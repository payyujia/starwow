const sql = require('../services/db');

exports.getInventory = async function(user) {
  const result = await sql`
      SELECT * FROM Inventory WHERE playerid = ${user};
    `;
    return result;
}
