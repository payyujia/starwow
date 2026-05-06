const sql = require('../services/db');

exports.getByChest = async function(chest) {
  const result = await sql`
      SELECT * FROM Asset WHERE chest = ${chest};
    `;
    return result;
}
