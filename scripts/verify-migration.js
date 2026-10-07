const { Client } = require('pg');

(async () => {
  const client = new Client({
    host: 'aws-0-ap-southeast-2.pooler.supabase.com',
    port: 6543,
    user: 'postgres.lfruzdnubvluzsubnwsp',
    password: process.env.SUPABASE_DB_PASSWORD,
    database: 'postgres',
    ssl: { rejectUnauthorized: false },
  });
  await client.connect();
  const r = await client.query(`
    select table_name from information_schema.tables
    where table_schema='public'
      and table_name in ('users','members','fortunes','fortune_chats','purchases','wallet_ledger')
    order by table_name
  `);
  console.log('tables:', r.rows.map((x) => x.table_name).join(', '));
  const p = await client.query(`
    select tablename, rowsecurity from pg_tables
    where schemaname='public'
      and tablename in ('users','members','fortunes','fortune_chats','purchases','wallet_ledger')
    order by tablename
  `);
  for (const row of p.rows) {
    console.log('rls', row.tablename, row.rowsecurity);
  }
  await client.end();
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
