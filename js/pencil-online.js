// Online play for Pencil Chess, backed by the portal's Supabase project.
//
// pencil-chess.html was written against a tiny document-database interface
// (doc().get/set/update/delete/onSnapshot, collection().where().limit()
// .onSnapshot, USER.id/can/profiles). This adapter provides exactly that on
// top of the public.pencil_games table (see sql/030_pencil_guest_play.sql), so
// the game code itself stays untouched.
//
// Nobody signs up or signs in. Each browser keeps a random secret token in
// localStorage; the game's "seat id" is the SHA-256 hash of that token, so what
// is stored and visible to other players never reveals the secret. Reading is
// plain table reads (plus realtime); every change goes through the pencil_*
// database functions, which check the token against the seat.
import { supabase } from "./supabase.js";

const TABLE = "pencil_games";
const TOKEN_KEY = "pc-secret";
const nameCache = {};

function secretToken() {
  try {
    let t = localStorage.getItem(TOKEN_KEY);
    if (!t || t.length < 16) {
      const a = new Uint8Array(24);
      crypto.getRandomValues(a);
      t = Array.from(a, (b) => b.toString(16).padStart(2, "0")).join("");
      localStorage.setItem(TOKEN_KEY, t);
    }
    return t;
  } catch (e) {
    const a = new Uint8Array(24);
    crypto.getRandomValues(a);
    return Array.from(a, (b) => b.toString(16).padStart(2, "0")).join("");
  }
}

async function sha256Hex(text) {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return Array.from(new Uint8Array(buf), (b) => b.toString(16).padStart(2, "0")).join("");
}

function guestName() {
  try {
    let n = localStorage.getItem("pc-guest-name");
    if (!n) {
      n = `Guest ${10 + Math.floor(Math.random() * 90)}`;
      localStorage.setItem("pc-guest-name", n);
    }
    return n;
  } catch (e) {
    return "Guest";
  }
}

const rowData = (row) => {
  const d = { ...row.data, status: row.status };
  if (d.names) Object.assign(nameCache, d.names);
  return d;
};
const snap = (row) => ({ exists: !!row, data: () => (row ? rowData(row) : undefined) });

function makeDb(token, me, myName) {
  const doc = (path) => {
    const code = path.split("/")[1];
    const fetchRow = async () => {
      const { data, error } = await supabase.from(TABLE).select("*").eq("code", code).maybeSingle();
      if (error) throw error;
      return data;
    };

    return {
      async get() {
        return snap(await fetchRow());
      },

      async set(obj) {
        const data = { ...obj, names: { ...(obj.names || {}), [me]: myName } };
        delete data.status;
        const { error } = await supabase.rpc("pencil_create", { p_code: code, p_token: token, p_data: data });
        if (error) throw error;
      },

      // Read, merge, write guarded by the row's version counter; retried if the
      // other player's write lands in between.
      async update(patch) {
        for (let attempt = 0; attempt < 4; attempt++) {
          const row = await fetchRow();
          if (!row) throw Object.assign(new Error("not found"), { code: "not_found" });
          const body = { ...patch, names: { ...(row.data.names || {}), [me]: myName } };
          const { data: ok, error } = await supabase.rpc("pencil_patch", {
            p_code: code,
            p_token: token,
            p_patch: body,
            p_ver: row.ver,
          });
          if (error) throw error;
          if (ok) return;
        }
        throw Object.assign(new Error("conflict"), { code: "conflict" });
      },

      async delete() {
        const { error } = await supabase.rpc("pencil_delete", { p_code: code, p_token: token });
        if (error) throw error;
      },

      // The database refuses a second player taking an occupied seat, so no
      // separate lock is needed.
      async acquire() {
        return { acquired: true };
      },

      onSnapshot(cb, errCb) {
        let alive = true;
        let last = null;
        let first = true;
        const push = async () => {
          try {
            const row = await fetchRow();
            if (!alive) return;
            const key = row ? `${row.ver}:${row.status}` : "none";
            if (key === last) return;
            last = key;
            first = false;
            cb(snap(row));
          } catch (e) {
            if (alive && first && errCb) {
              alive = false;
              errCb(e);
            }
          }
        };
        push();
        const ch = supabase
          .channel(`pc-${code}-${Math.random().toString(36).slice(2, 8)}`)
          .on("postgres_changes", { event: "*", schema: "public", table: TABLE, filter: `code=eq.${code}` }, push)
          .subscribe();
        const timer = setInterval(push, 4000);
        return () => {
          alive = false;
          clearInterval(timer);
          supabase.removeChannel(ch);
        };
      },
    };
  };

  const collection = () => ({
    where(field, _op, value) {
      return {
        limit(n) {
          const run = async () => {
            const { data, error } = await supabase
              .from(TABLE)
              .select("*")
              .eq(field, value)
              .order("created_at", { ascending: false })
              .limit(n);
            if (error) throw error;
            return data || [];
          };
          return {
            onSnapshot(cb, errCb) {
              let alive = true;
              let last = null;
              let first = true;
              const push = async () => {
                try {
                  const rows = await run();
                  if (!alive) return;
                  const key = rows.map((r) => `${r.code}:${r.ver}`).join("|");
                  if (key === last) return;
                  last = key;
                  first = false;
                  cb({ docs: rows.map((r) => ({ data: () => rowData(r) })) });
                } catch (e) {
                  if (alive && first && errCb) {
                    alive = false;
                    errCb(e);
                  }
                }
              };
              push();
              const ch = supabase
                .channel(`pc-lobby-${Math.random().toString(36).slice(2, 8)}`)
                .on("postgres_changes", { event: "*", schema: "public", table: TABLE }, push)
                .subscribe();
              const timer = setInterval(push, 5000);
              return () => {
                alive = false;
                clearInterval(timer);
                supabase.removeChannel(ch);
              };
            },
          };
        },
      };
    },
  });

  // Live "who has this game open" signal (Supabase realtime presence). A player
  // who is merely thinking stays connected and therefore present; closing or
  // backgrounding the tab drops them. Calls cb(ids) with the seat ids present.
  const presence = (code, cb) => {
    const ch = supabase.channel(`pc-pres-${code}`, { config: { presence: { key: me } } });
    ch.on("presence", { event: "sync" }, () => cb(Object.keys(ch.presenceState())));
    ch.subscribe((status) => {
      if (status === "SUBSCRIBED") ch.track({ at: Date.now() });
    });
    return () => supabase.removeChannel(ch);
  };

  return { doc, collection, presence };
}

export async function connect() {
  if (!window.crypto || !crypto.subtle) {
    return { db: null, user: null, why: "Online play needs a secure (https) connection." };
  }
  const token = secretToken();
  const me = await sha256Hex(token);
  const name = guestName();
  nameCache[me] = name;
  return {
    db: makeDb(token, me, name),
    user: {
      id: async () => me,
      can: async () => true,
      profiles: async (ids) =>
        Object.fromEntries(ids.filter((i) => nameCache[i]).map((i) => [i, { name: nameCache[i] }])),
    },
    why: "",
  };
}
