function Hide()
{
   _parent.help_mc._visible = false;
   titleTxt._visible = false;
   img_mc._visible = false;
   diceBox._visible = false;
   armorBox._visible = false;
   actionBox._visible = false;
}
function Show()
{
   _parent.help_mc._visible = true;
   titleTxt._visible = true;
   img_mc._visible = true;
   if(obj.Dice > 0)
   {
      diceBox._visible = true;
   }
   if(obj.Defence > 0)
   {
      armorBox._visible = true;
   }
   if(obj.Action > 0)
   {
      actionBox._visible = true;
   }
}
if(BattleSystem.PickInPlayerArray)
{
   var rndCard = random(BattleSystem.Player.CardDeck.length);
   if(BATTLESYSTEM_DEBUG)
   {
      rndCard = 0;
   }
   _parent.CardID = CardID = BattleSystem.Player.CardDeck[rndCard];
   BattleSystem.Player.CardDeck.splice(rndCard,1);
}
else
{
   var rndCard = random(BattleSystem.Opponent.CardDeck.length);
   if(BATTLESYSTEM_DEBUG)
   {
      rndCard = 0;
   }
   _parent.CardID = CardID = BattleSystem.Opponent.CardDeck[rndCard];
   BattleSystem.Opponent.CardDeck.splice(rndCard,1);
}
var obj = BattleSystem.LookUpCard(CardID);
if(obj.Dice > 0)
{
   diceBox.Text.txtValue.text = obj.Dice;
}
else
{
   diceBox._visible = false;
}
if(obj.Defence > 0)
{
   armorBox.Text.txtValue.text = obj.Defence;
}
else
{
   armorBox._visible = false;
}
if(obj.Action > 0)
{
   actionBox.Text.txtValue.text = obj.Action;
}
else
{
   actionBox._visible = false;
}
titleTxt.text = obj.Name;
gotoAndStop("ID_" + CardID);
if(!BattleSystem.PickInPlayerArray)
{
   Hide();
}
