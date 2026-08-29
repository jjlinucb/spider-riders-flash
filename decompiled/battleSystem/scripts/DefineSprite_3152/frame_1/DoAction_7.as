function OpponentDiceTotal()
{
   var _loc1_ = 0;
   _loc1_ += Opponent.Dice;
   _loc1_ += Opponent.Spider.Dice;
   _loc1_ += !DeckOpponentUI.Socket01.Card.IsActive ? 0 : LookUpCard(DeckOpponentUI.Socket01.Card.CardID).Dice;
   _loc1_ += !DeckOpponentUI.Socket02.Card.IsActive ? 0 : LookUpCard(DeckOpponentUI.Socket02.Card.CardID).Dice;
   _loc1_ += !DeckOpponentUI.Socket03.Card.IsActive ? 0 : LookUpCard(DeckOpponentUI.Socket03.Card.CardID).Dice;
   _loc1_ += !DeckOpponentUI.Socket04.Card.IsActive ? 0 : LookUpCard(DeckOpponentUI.Socket04.Card.CardID).Dice;
   _loc1_ += !DeckOpponentUI.Socket05.Card.IsActive ? 0 : LookUpCard(DeckOpponentUI.Socket05.Card.CardID).Dice;
   _loc1_ += !DeckOpponentUI.Socket06.Card.IsActive ? 0 : LookUpCard(DeckOpponentUI.Socket06.Card.CardID).Dice;
   _loc1_ += !DeckOpponentUI.Socket07.Card.IsActive ? 0 : LookUpCard(DeckOpponentUI.Socket07.Card.CardID).Dice;
   return _loc1_;
}
function OpponentDefenceTotal()
{
   var _loc1_ = 0;
   _loc1_ += Opponent.Defence;
   _loc1_ += Opponent.Spider.Defence;
   _loc1_ += !DeckOpponentUI.Socket01.Card.IsActive ? 0 : LookUpCard(DeckOpponentUI.Socket01.Card.CardID).Defence;
   _loc1_ += !DeckOpponentUI.Socket02.Card.IsActive ? 0 : LookUpCard(DeckOpponentUI.Socket02.Card.CardID).Defence;
   _loc1_ += !DeckOpponentUI.Socket03.Card.IsActive ? 0 : LookUpCard(DeckOpponentUI.Socket03.Card.CardID).Defence;
   _loc1_ += !DeckOpponentUI.Socket04.Card.IsActive ? 0 : LookUpCard(DeckOpponentUI.Socket04.Card.CardID).Defence;
   _loc1_ += !DeckOpponentUI.Socket05.Card.IsActive ? 0 : LookUpCard(DeckOpponentUI.Socket05.Card.CardID).Defence;
   _loc1_ += !DeckOpponentUI.Socket06.Card.IsActive ? 0 : LookUpCard(DeckOpponentUI.Socket06.Card.CardID).Defence;
   _loc1_ += !DeckOpponentUI.Socket07.Card.IsActive ? 0 : LookUpCard(DeckOpponentUI.Socket07.Card.CardID).Defence;
   return _loc1_;
}
function OpponentHitPointTotal()
{
   var _loc1_ = 0;
   _loc1_ += Opponent.LifePoint;
   _loc1_ += Opponent.LifePointReserve;
   return _loc1_;
}
function OpponentShieldCardInGame()
{
   var _loc1_ = 0;
   _loc1_ += !(DeckOpponentUI.Socket01.Card.CardID >= 200 && DeckOpponentUI.Socket01.Card.CardID < 300 && DeckOpponentUI.Socket01.Card != VoidCard) ? 0 : 1;
   _loc1_ += !(DeckOpponentUI.Socket02.Card.CardID >= 200 && DeckOpponentUI.Socket02.Card.CardID < 300 && DeckOpponentUI.Socket02.Card != VoidCard) ? 0 : 1;
   _loc1_ += !(DeckOpponentUI.Socket03.Card.CardID >= 200 && DeckOpponentUI.Socket03.Card.CardID < 300 && DeckOpponentUI.Socket03.Card != VoidCard) ? 0 : 1;
   _loc1_ += !(DeckOpponentUI.Socket04.Card.CardID >= 200 && DeckOpponentUI.Socket04.Card.CardID < 300 && DeckOpponentUI.Socket04.Card != VoidCard) ? 0 : 1;
   _loc1_ += !(DeckOpponentUI.Socket05.Card.CardID >= 200 && DeckOpponentUI.Socket05.Card.CardID < 300 && DeckOpponentUI.Socket05.Card != VoidCard) ? 0 : 1;
   _loc1_ += !(DeckOpponentUI.Socket06.Card.CardID >= 200 && DeckOpponentUI.Socket06.Card.CardID < 300 && DeckOpponentUI.Socket06.Card != VoidCard) ? 0 : 1;
   _loc1_ += !(DeckOpponentUI.Socket07.Card.CardID >= 200 && DeckOpponentUI.Socket07.Card.CardID < 300 && DeckOpponentUI.Socket07.Card != VoidCard) ? 0 : 1;
   return _loc1_;
}
function OpponentActionTotal()
{
   return 7;
}
function HurtOpponent(damage)
{
   var _loc1_ = damage;
   var _loc2_ = 0;
   if(Opponent.LifePointReserve > 0)
   {
      if(Opponent.LifePointReserve > _loc1_)
      {
         Opponent.LifePointReserve -= _loc1_;
      }
      else
      {
         _loc2_ = _loc1_ - Opponent.LifePointReserve;
         Opponent.LifePointReserve = 0;
         Opponent.LifePoint -= _loc2_;
      }
   }
   else
   {
      Opponent.LifePoint -= _loc1_;
   }
   if(Opponent.LifePoint <= 0)
   {
      Opponent.LifePoint = 0;
      IsWinner = true;
      IsGameOver = true;
   }
}
var Opponent = new Object();
Opponent.ID = BattleSystem._parent.FromEngineOpponent.type;
Opponent.Name = LookUpMonster(Opponent.ID).Name;
Opponent.Rank = LookUpMonster(Opponent.ID).Rank;
Opponent.Dice = LookUpMonster(Opponent.ID).Dice;
Opponent.Defence = LookUpMonster(Opponent.ID).Defence;
Opponent.Action = LookUpMonster(Opponent.ID).Action;
Opponent.LifePoint = LookUpMonster(Opponent.ID).LifePoint;
Opponent.VictoryPoint = LookUpMonster(Opponent.ID).VictoryPoint;
Opponent.LifePointReserve = 0;
Opponent.Spider = new Object();
Opponent.Spider.ID = "ID_SPIDER";
Opponent.Spider.Name = "";
Opponent.Spider.Dice = 0;
Opponent.Spider.Defence = 0;
Opponent.Spider.Action = 0;
Opponent.Spider.LifePoint = 0;
Opponent.Spider.VictoryPoint = 0;
Opponent.Spider.Rider = Opponent;
Opponent.CardDeck = new Array();
var i = 0;
while(i < BattleSystem._parent.FromEngineOpponent.card.length)
{
   Opponent.CardDeck.push(BattleSystem._parent.FromEngineOpponent.card[i]);
   i++;
}
