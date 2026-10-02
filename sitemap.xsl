<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:sm="http://www.sitemaps.org/schemas/sitemap/0.9">
  <xsl:output method="html" encoding="UTF-8" indent="yes" doctype-system="about:legacy-compat"/>

  <xsl:template match="/">
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <meta name="robots" content="noindex"/>
        <title>Sitemap | Maldives Chess Club Student Portal</title>
        <style>
          body { margin: 0; background: #fbf6ec; color: #2b1a1f; font-family: system-ui, -apple-system, "Segoe UI", Arial, sans-serif; line-height: 1.5; }
          header { background: #4b0a22; color: #fbf6ec; padding: 28px 20px; }
          header h1 { margin: 0 0 4px; font-family: Georgia, serif; font-size: 1.6rem; }
          header p { margin: 0; color: #f3e6c4; }
          main { max-width: 760px; margin: 0 auto; padding: 24px 20px 48px; }
          p.note { color: #7a6a6e; margin: 0 0 18px; }
          table { width: 100%; border-collapse: collapse; background: #fffdf8; border: 1px solid #e8dccb; border-radius: 10px; overflow: hidden; }
          th, td { text-align: left; padding: 12px 14px; border-bottom: 1px solid #e8dccb; }
          th { background: #f1e6d6; font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.04em; color: #4b0a22; }
          tr:last-child td { border-bottom: 0; }
          a { color: #6e1433; font-weight: 600; word-break: break-all; }
          a:hover { color: #4b0a22; }
          td.date { white-space: nowrap; color: #7a6a6e; }
          @media (max-width: 480px) { th:last-child, td.date { display: none; } }
        </style>
      </head>
      <body>
        <header>
          <h1>Sitemap</h1>
          <p>Maldives Chess Club Student Portal</p>
        </header>
        <main>
          <p class="note">
            This is the list of public pages that search engines can index.
            There are <xsl:value-of select="count(sm:urlset/sm:url)"/> pages.
          </p>
          <table>
            <thead>
              <tr><th>Page</th><th>Last updated</th></tr>
            </thead>
            <tbody>
              <xsl:for-each select="sm:urlset/sm:url">
                <tr>
                  <td><a href="{sm:loc}"><xsl:value-of select="sm:loc"/></a></td>
                  <td class="date"><xsl:value-of select="sm:lastmod"/></td>
                </tr>
              </xsl:for-each>
            </tbody>
          </table>
        </main>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
