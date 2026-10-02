// Online play for Pencil Chess, backed by the portal's Supabase project.
//
// pencil-chess.html was written against a tiny document-database interface
// (doc().get/set/update/delete/onSnapshot, collection().where().limit()
// .onSnapshot, USER.id/can/profiles). This adapter provides exactly that on
// top of the public.pencil_games table (see sql/029_pencil_chess.sql), so the
// game code itself stays untouched. Online play needs a signed-in portal
// account; playing the computer or a friend on one device does not.
import { supabase } from "./supabase.js";

const TABLE = "pencil_games";
const nameCache = {};

async function firstName(uid) {
  try {
    const [{ data: s }, { data: c }] = await Promise.all([
      supabase.from("students").select("full_name").eq("id", uid).maybeSingle(),
      supabase.from("coaches").select("name").eq("id", uid).maybeSingle(),
    ]);
    const full = (s && s.full_name) || (c && c.name) || "";
    return full.trim().split(/\s+/)[0] || "A player";
  } catch (e) {
    return "A player";
  }
}

const rowData = (row) => {
  const d = { ...row.data, status: row.status };
  if (d.names) Object.assign(nameCache, d.names);
  return d;
};
const snap = (row) => ({ exists: !!row, data: () => (row ? rowData(row) : undefined) });

function makeDb(uid, myName) {
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
        const data = { ...obj, names: { ...(obj.names || {}), [uid]: myName } };
        delete data.status;
        const { error } = await supabase.from(TABLE).insert({ code, status: obj.status || "waiting", data });
        if (error) throw error;
      },

      // Read-merge-write guarded by the row's version counter, retried if the
      // other player's write lands in between.
      async update(patch) {
        for (let attempt = 0; attempt < 4; attempt++) {
          const row = await fetchRow();
          if (!row) throw Object.assign(new Error("not found"), { code: "not_found" });
          const merged = { ...row.data, ...patch, names: { ...(row.data.names || {}), [uid]: myName } };
          delete merged.status;
          const status = patch.status || row.status;
          const { data: upd, error } = await supabase
            .from(TABLE)
            .update({ status, data: merged })
            .eq("code", code)
            .eq("ver", row.ver)
            .select("ver");
          if (error) throw error;
          if (upd && upd.length) return;
        }
        throw Object.assign(new Error("conflict"), { code: "conflict" });
      },

      async delete() {
        const { error } = await supabase.from(TABLE).delete().eq("code", code);
        if (error) throw error;
      },

      // The database trigger refuses a second player taking an occupied seat,
      // so no separate lock is needed.
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

  return { doc, collection };
}

export async function connect() {
  const { data } = await supabase.auth.getSession();
  const user = data && data.session && data.session.user;
  if (!user) {
    return {
      db: null,
      user: null,
      why: "Sign in to the portal to play online. Playing the computer works without signing in.",
    };
  }
  const name = await firstName(user.id);
  nameCache[user.id] = name;
  return {
    db: makeDb(user.id, name),
    user: {
      id: async () => user.id,
      can: async () => true,
      profiles: async (ids) => Object.fromEntries(ids.filter((i) => nameCache[i]).map((i) => [i, { name: nameCache[i] }])),
    },
    why: "",
  };
}
