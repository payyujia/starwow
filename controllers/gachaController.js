const User = require('../models/userModel')
const Inventory = require('../models/inventoryModel')
const Asset = require('../models/assetModel')
const chests = [
    {name:'Sunshine Chic',price:'40000C',id:'sunshine',chestImg:null,card:null},
    {name:'Beach Carnival',price:'500D',id:'beach',chestImg:null,card:null},
    {name:'Glam Party',price:'500D',id:'glam',chestImg:null,card:null}
]

//get / show all chest options
module.exports.home = async (req, res) => {
    try {
        res.render('tent', { chests })
    } catch (err) {
        res.status(500).send(err.message)
    }
}

// GET /:chestId 
module.exports.viewChest = async (req, res) => {
    try {
        const chestId = req.params.chestId
        const userId = 1//testing

        const assets = await Asset.getByChest(chestId)
        const inventory = await Inventory.getInventory(userId)


        res.render('chest', { assets })
    } catch (err) {
        res.status(500).send(err.message)
    }
}
module.exports.pullTreasure = async (req, res) => {
    try {
        res.send('yay')
    } catch (err) {
        console.error(err)
        res.status(500).send(err.message)
    }
}
