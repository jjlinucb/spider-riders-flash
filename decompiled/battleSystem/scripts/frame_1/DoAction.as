function initBattle(battleOpponent, battlePlayer, param)
{
   var _loc1_ = battlePlayer;
   FromEnginePlayer = _loc1_;
   FromEngineOpponent = battleOpponent;
   FromEngineParam = param;
   mainChar.typeBody = 4 + root.typeArmor;
   mainChar.typeLegs = 4 + root.typeArmor;
   if(_loc1_.card.length > 7)
   {
      if(cardQty < 8)
      {
         cardQty = _loc1_.card.length;
         if(root.inWorld != true)
         {
            if(root.playerStats.mission == 1)
            {
               showTutorial = true;
            }
         }
      }
   }
   this.gotoAndStop(2);
}
function clearBattle()
{
   root.optionBar.scoreTxt.text = root.playerStats.victory + BattleSystem.VictoryPoint;
   mainChar.resetPerso();
   game.char.play();
   clearInterval(intervalID);
   BattleSystem.Destroy();
   this.gotoAndStop(1);
}
_global.BATTLESYSTEM_DEBUG = false;
if(battleInitCard == undefined)
{
   cardQty = root.playerStats.card.length;
   battleInitCard = true;
}
showTutorial = false;
if(!BATTLESYSTEM_DEBUG)
{
   stop();
}
else
{
   _global.mainChar = this;
   mainChar.tempSex = 1;
   mainChar.typeSex = "male";
   mainChar.typeHair = 1;
   mainChar.typeEyes = 1;
   mainChar.typeSkin = 1;
   mainChar.typeBody = 1;
   mainChar.typeLegs = 1;
   mainChar.typeArmor = 2;
   mainChar.typeManacle = 1;
   FromEnginePlayer = new Object();
   FromEnginePlayer.type = 604;
   FromEnginePlayer.name = "BillyBob le Conquerant";
   FromEnginePlayer.rank = 6;
   FromEnginePlayer.dice = 10;
   FromEnginePlayer.defense = 10;
   FromEnginePlayer.action = 11;
   FromEnginePlayer.life = 25;
   FromEnginePlayer.victory = 0;
   mainChar.sprSex = 1;
   FromEnginePlayer.spider = {dice:3,defense:3,action:3};
   _global.root = this;
   root.deckActive = "A";
   FromEnginePlayer.card = new Array();
   var obj = new Object();
   obj = {id:202,deck:1};
   FromEnginePlayer.card.push(obj);
   var obj = new Object();
   obj = {id:600,deck:1};
   FromEnginePlayer.card.push(obj);
   var obj = new Object();
   obj = {id:601,deck:1};
   FromEnginePlayer.card.push(obj);
   var obj = new Object();
   obj = {id:208,deck:1};
   FromEnginePlayer.card.push(obj);
   var obj = new Object();
   obj = {id:102,deck:1};
   FromEnginePlayer.card.push(obj);
   var obj = new Object();
   obj = {id:100,deck:1};
   FromEnginePlayer.card.push(obj);
   var obj = new Object();
   obj = {id:101,deck:1};
   FromEnginePlayer.card.push(obj);
   var obj = new Object();
   obj = {id:203,deck:1};
   FromEnginePlayer.card.push(obj);
   FromEngineOpponent = new Object();
   FromEngineOpponent.type = 615;
}
