const express = require('express');
const router = express.Router();
const gacha = require('../controllers/gachaController');

router.get('/', gacha.home);
router.get('/:chestId', gacha.viewChest); // ← new
router.post('/buy', gacha.pullTreasure);

module.exports = router;