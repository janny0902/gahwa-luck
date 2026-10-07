// 사용: SUPABASE_ACCESS_TOKEN 환경변수 설정 후 node scripts/apply-sql.js <sql 파일>
const fs = require('fs');

const token = (process.env.SUPABASE_ACCESS_TOKEN || '').trim();
const file = process.argv[2];
if (!token || !file) {
  console.error('usage: SUPABASE_ACCESS_TOKEN=... node scripts/apply-sql.js <file.sql>');
  process.exit(1);
}

const url = 'https://api.supabase.com/v1/projects/lfruzdnubvluzsubnwsp/database/query';

(async () => {
  const response = await fetch(url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ query: fs.readFileSync(file, 'utf8'), read_only: false }),
  });
  const text = await response.text();
  console.log('status', response.status);
  console.log(text.slice(0, 600));
  if (!response.ok) process.exit(1);
})();
