const sql = require('../services/db');

exports.getStats = async function(user) {
  const result = await sql`
      SELECT * FROM player WHERE playerid = ${user};
    `;
    return result;
}
