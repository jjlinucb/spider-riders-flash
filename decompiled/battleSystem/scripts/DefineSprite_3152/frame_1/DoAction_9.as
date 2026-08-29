function Launch()
{
   Console.Write("<launch>");
   Init();
}
function Init()
{
   SetMode(MODE_INIT);
   broadcastMessage("onBattleSystemInit");
   broadcastMessage("onBattleSystemUpdate");
   IsStarted = true;
   AIInit();
   CardInHandPlayer = Math.min(Math.min(Player.CardDeck.length,PlayerActionTotal()),7);
   CardInHandOpponent = Math.min(Math.min(Opponent.CardDeck.length,OpponentActionTotal()),7);
   IndexCardDeal = 1;
   intervalID = setInterval(DealPlayer,250);
}
function DealPlayer()
{
   var card = null;
   CardDrawer = DRAW_PLAYER;
   DeckCardCounterPlayer.Update();
   if(CardInHandPlayer > 0)
   {
      card = Generate(GENERATE_CARD_PLAYER);
      socketTarget = eval("DeckPlayerInHandUI.Socket0" + IndexCardDeal);
      card._x = Deck._x;
      card._y = Deck._y;
      card._visible = true;
      card.Socket = socketTarget;
      card.isPlayerCard = true;
      socketTarget.Card = card;
      IndexCardDeal++;
      card.onEnterFrame = MoveToSocket;
   }
   if(IndexCardDeal > CardInHandPlayer)
   {
      IndexCardDeal = 1;
      clearInterval(intervalID);
      WaitCallback = function()
      {
         clearInterval(intervalID);
         intervalID = setInterval(DealOpponent,250);
      };
      intervalID = setInterval(Wait,1000);
   }
}
function DealOpponent()
{
   var card = null;
   CardDrawer = DRAW_OPPONENT;
   DeckCardCounterOpponent.Update();
   if(CardInHandOpponent > 0)
   {
      card = Generate(GENERATE_CARD_OPPONENT);
      socketTarget = eval("DeckOpponentUI.Socket0" + IndexCardDeal);
      card._x = DeckOpponent._x;
      card._y = DeckOpponent._y;
      card._visible = true;
      card.Socket = socketTarget;
      card.isPlayerCard = false;
      card.CardCloner.btn.enabled = false;
      socketTarget.Card = card;
      IndexCardDeal++;
      card.onEnterFrame = MoveToSocket;
   }
   if(IndexCardDeal > CardInHandOpponent)
   {
      clearInterval(intervalID);
      WaitCallback = InitAfterDraw;
      intervalID = setInterval(Wait,500);
   }
}
function InitAfterDraw()
{
   clearInterval(intervalID);
   SetMode(MODE_CHOOSE);
   if(Opponent.ID < 200)
   {
      CurrentPlayer = TURN_PLAYER;
   }
   else if(Opponent.ID < 300)
   {
      CurrentPlayer = TURN_OPPONENT;
   }
   else
   {
      CurrentPlayer = Math.random() >= 0.5 ? TURN_OPPONENT : TURN_PLAYER;
   }
   broadcastMessage("onBattleSystemChoosePlayer");
   if(CurrentPlayer == TURN_PLAYER)
   {
      if(Player.CardDeck.length > CardInHand)
      {
         DrawCardPlayer();
         Deck.gotoAndStop("NORMAL");
         CardOnTop = true;
      }
      else
      {
         Deck.gotoAndStop("EMPTY");
         CardOnTop = false;
      }
      statPlayerTotal.Dice.gotoAndStop("HIGHLIGHT");
      statPlayerTotal.Defence.gotoAndStop("DISABLE");
      statOpponentTotal.Dice.gotoAndStop("DISABLE");
      statOpponentTotal.Defence.gotoAndStop("HIGHLIGHT");
   }
   else
   {
      if(Opponent.ID < 200)
      {
         WaitCallback = NextTurn;
      }
      else
      {
         DrawCardOpponent();
         WaitCallback = AILaunch;
      }
      intervalID = setInterval(Wait,500);
      statPlayerTotal.Dice.gotoAndStop("DISABLE");
      statPlayerTotal.Defence.gotoAndStop("HIGHLIGHT");
      statOpponentTotal.Dice.gotoAndStop("HIGHLIGHT");
      statOpponentTotal.Defence.gotoAndStop("DISABLE");
      if(Player.CardDeck.length > CardInHand)
      {
         Deck.gotoAndStop("NORMAL");
      }
      else
      {
         Deck.gotoAndStop("EMPTY");
      }
   }
   if(IsFirstBattle && root.playerStats.mission == 1)
   {
      if(root.inWorld != true)
      {
         Tutorial.gotoAndPlay("open");
      }
   }
   SetMode(MODE_NEXT_TURN);
}
function Update()
{
   if(IsStarted)
   {
      if(HasMouseReleased)
      {
         if(IsDraging)
         {
            Release();
         }
      }
      frame % 30 != 0 ? null : broadcastMessage("onBattleSystemUpdate");
   }
}
function Destroy()
{
   clearInterval(intervalID);
   SetMode(MODE_NONE);
   broadcastMessage("onBattleSystemDestroy");
   IsStarted = false;
}
function NextTurn()
{
   clearInterval(intervalID);
   DiceRed = 0;
   DiceBlue = 0;
   WhiteDice = 0;
   YellowDicesUsed++;
   if(CurrentPlayer == TURN_PLAYER)
   {
      CurrentPlayer = TURN_OPPONENT;
      if(Opponent.ID < 200)
      {
         WaitCallback = NextTurn;
      }
      else
      {
         if(Opponent.CardDeck.length > 0)
         {
            DrawCardOpponent();
         }
         WaitCallback = AILaunch;
      }
      statPlayerTotal.Dice.gotoAndStop("DISABLE");
      statPlayerTotal.Defence.gotoAndStop("HIGHLIGHT");
      statOpponentTotal.Dice.gotoAndStop("HIGHLIGHT");
      statOpponentTotal.Defence.gotoAndStop("DISABLE");
      intervalID = setInterval(Wait,500);
   }
   else
   {
      CurrentPlayer = TURN_PLAYER;
      if(Player.CardDeck.length > 0)
      {
         DrawCardPlayer();
         clearInterval(intervalID);
         slot = PlayerFindEmptySlot();
         if(slot != null)
         {
            Deck.Card.Socket = slot;
            Deck.Card.onEnterFrame = MoveToSocket;
            Deck.Card = VoidCard;
            CardOnTop = false;
         }
         else
         {
            CardOnTop = true;
         }
      }
      statPlayerTotal.Dice.gotoAndStop("HIGHLIGHT");
      statPlayerTotal.Defence.gotoAndStop("DISABLE");
      statOpponentTotal.Dice.gotoAndStop("DISABLE");
      statOpponentTotal.Defence.gotoAndStop("HIGHLIGHT");
   }
   root.sfx.gotoAndPlay("NextTurn");
   SetMode(MODE_NEXT_TURN);
}
function DrawCardPlayer()
{
   var _loc1_;
   if(Player.CardDeck.length > 0)
   {
      if(!CutiePieEq && !blessingCardEq)
      {
         SetMode(MODE_DRAW);
         CardDrawer = DRAW_PLAYER;
      }
      _loc1_ = Generate(GENERATE_CARD_PLAYER);
      _loc1_.isPlayerCard = true;
      _loc1_._x = Deck._x + Deck.Socket._x;
      _loc1_._y = Deck._y + Deck.Socket._y;
      _loc1_._visible = true;
      Deck.Card = _loc1_;
      root.sfx.gotoAndPlay("Draw");
   }
}
function DrawCardOpponent()
{
   var _loc1_;
   if(Opponent.CardDeck.length > 0)
   {
      SetMode(MODE_DRAW);
      CardDrawer = DRAW_OPPONENT;
      _loc1_ = Generate(GENERATE_CARD_OPPONENT);
      _loc1_.isPlayerCard = false;
      _loc1_.CardCloner.btn.enabled = false;
      _loc1_._x = DeckOpponent._x + DeckOpponent.Socket._x;
      _loc1_._y = DeckOpponent._y + DeckOpponent.Socket._y;
      _loc1_._visible = true;
      DeckOpponent.Card = _loc1_;
      root.sfx.gotoAndPlay("Draw");
   }
}
function ThrowDice()
{
   clearInterval(intervalID);
   SetMode(MODE_DICE_THROW);
   column = 0;
   row = 0;
   Dices = new Array();
   intervalID = setInterval(NewDice,100);
}
function NewDice()
{
   var _loc1_ = this;
   dice = Generate(GENERATE_DICE);
   dice._x = 178 + column * 32;
   dice._y = 215 + row * 32;
   dice.Socket = Deck.Socket;
   dice.indexDices = Dices.length - 1;
   dice.IsReady = false;
   if(column >= 8)
   {
      column = 0;
      row++;
   }
   else
   {
      column++;
   }
   Shake(dice);
   Dices.push(dice);
   if(Dices.length >= CurrentAttack.Dice)
   {
      clearInterval(intervalID);
      dice.onEnterFrame = function()
      {
         var _loc1_ = this;
         if(_loc1_.IsReady)
         {
            _loc1_.IsReady = false;
            delete _loc1_.onEnterFrame;
            BattleSystem.clearInterval(BattleSystem.intervalID);
            BattleSystem.WaitCallback = BattleSystem.RemoveWhiteDice;
            BattleSystem.intervalID = setInterval(BattleSystem.Wait,500);
            BattleSystem.SetMode(BattleSystem.MODE_DICE_ANIM_WHITE);
         }
      };
   }
   root.sfx.gotoAndPlay("ThrowDice");
}
function RemoveWhiteDice()
{
   for(var _loc1_ in Dices)
   {
      if(Dices[_loc1_].Type == DICE_WHITE)
      {
         BattleSystem.WhiteDice++;
         Dices[_loc1_].gotoAndStop("REMOVE");
         Dices[_loc1_].splice(_loc1_,1);
      }
   }
   clearInterval(intervalID);
   intervalID = setInterval(CumulateRedDice,1000);
   root.sfx.gotoAndPlay("DiceRemove");
   SetMode(MODE_DICE_ANIM_RED);
}
function CumulateRedDice()
{
   for(var _loc1_ in Dices)
   {
      if(Dices[_loc1_].Type == DICE_RED)
      {
         Dices[_loc1_].Socket = CurrentPlayer != TURN_PLAYER ? targetRedOpponent : targetRedPlayer;
         Dices[_loc1_].onEnterFrame = MoveTo;
         Dices[_loc1_].halo.gotoAndPlay("GLOW");
         Dices.splice(_loc1_,1);
         clearInterval(intervalID);
         root.sfx.gotoAndPlay("DiceMove");
         break;
      }
   }
}
function CumulateBlueDice()
{
   clearInterval(intervalID);
   SetMode(MODE_CARD);
   var _loc1_ = 0;
   while(_loc1_ < Dices.length)
   {
      Dices[_loc1_].halo.gotoAndPlay("GLOW_IN_OUT");
      _loc1_ = _loc1_ + 1;
   }
   if(CurrentPlayer == TURN_PLAYER && IsFirstBattle && root.playerStats.mission == 1)
   {
      if(root.inWorld != true)
      {
         Tutorial.gotoAndPlay("attack");
      }
   }
   if(CurrentPlayer == TURN_OPPONENT)
   {
      WaitCallback = function()
      {
         clearInterval(intervalID);
         AIPhaseDice();
      };
      intervalID = setInterval(Wait,250);
   }
}
function Attack()
{
   clearInterval(intervalID);
   RemoveDice();
   LastActionDamage = BattleSystem.CurrentAttack.Action;
   if(LastActionDamage > 0)
   {
      if(CurrentPlayer == TURN_PLAYER)
      {
         HurtOpponent(LastActionDamage);
      }
      else
      {
         HurtPlayer(LastActionDamage);
      }
      Console.Write("<attack : " + LastActionDamage + ">");
   }
   else
   {
      root.sfx.gotoAndPlay("Block");
      Console.Write("<attack : FAIL>");
   }
   if(CurrentPlayer == TURN_PLAYER)
   {
      AnimPlayer.Avatar.gotoAndStop("ATTACK0" + (random(4) + 1));
   }
   else
   {
      AnimOpponent.Monster.gotoAndStop("ATTACK");
   }
   root.sfx.gotoAndPlay("Attack");
}
function Defend()
{
   if(CurrentPlayer == TURN_PLAYER)
   {
      AnimPlayer.Avatar.gotoAndStop("IDLE");
      if(LastActionDamage > 0)
      {
         if(OpponentHitPointTotal() <= 0)
         {
            statPlayerTotal.Update();
            statOpponentTotal.Update();
            meterLifePointOpponent._visible = false;
            AnimOpponent.Monster.gotoAndStop("DEAD");
         }
         else
         {
            AnimOpponent.Monster.gotoAndStop("HURT");
         }
      }
      else if(LastActionDamage <= 0)
      {
         AnimOpponent.Monster.gotoAndStop("BLOCK");
      }
   }
   else
   {
      AnimOpponent.Monster.gotoAndStop("IDLE");
      if(LastActionDamage > 0)
      {
         if(PlayerHitPointTotal() <= 0)
         {
            meterLifePointPlayer._visible = false;
            statPlayerTotal.Update();
            statOpponentTotal.Update();
            AnimPlayer.Avatar.gotoAndStop("DEAD");
         }
         else
         {
            AnimPlayer.Avatar.gotoAndStop("HURT");
         }
      }
      else if(LastActionDamage <= 0)
      {
         AnimPlayer.Avatar.gotoAndStop("BLOCK");
      }
   }
   SetMode(MODE_ACTION_DEFENSE);
   root.sfx.gotoAndPlay("Defend");
}
function CallbackDefenseIsDone()
{
   if(CurrentPlayer == TURN_PLAYER)
   {
      AnimPlayer.Avatar.gotoAndStop("IDLE");
      if(OpponentHitPointTotal() > 0)
      {
         AnimOpponent.Monster.gotoAndStop("IDLE");
      }
   }
   else
   {
      AnimPlayer.Avatar.gotoAndStop("IDLE");
      if(OpponentHitPointTotal() > 0)
      {
         AnimOpponent.Monster.gotoAndStop("IDLE");
      }
   }
   AttackIsDone();
}
function AttackIsDone()
{
   SetMode(MODE_ACTION_DAMAGE);
   if(IsGameOver)
   {
      GameOver();
   }
   else
   {
      RemoveCard();
   }
}
function Interupt()
{
   SetMode(MODE_ACTION_INTERUPT);
   if(CurrentPlayer == TURN_PLAYER)
   {
   }
   root.sfx.gotoAndPlay("Interupt");
}
function Retreat()
{
   SetMode(MODE_ACTION_RETREAT);
   root.sfx.gotoAndPlay("Interupt");
   BattleSystem._parent.CallbackEndBattle(false,0);
}
function Activate(card, nPlayer)
{
   var _loc1_ = card;
   var _loc2_ = nPlayer;
   root.Trace("\nJ\'active la carte : " + _loc1_.CardID);
   var _loc3_ = CurrentPlayer;
   if(_loc2_ != undefined)
   {
      CurrentPlayer = _loc2_;
   }
   _loc1_.CardCloner.Halo.gotoAndStop("ACTIVE");
   _loc1_.IsActive = true;
   if(IsBlueCard(_loc1_) || IsFusionCard(_loc1_))
   {
      BattleSystem.MalusOpponent = Number(BattleSystem.MalusOpponent);
      BattleSystem.MalusPlayer = Number(BattleSystem.MalusPlayer);
      BattleSystem.DefendMalusOpponent = Number(BattleSystem.DefendMalusOpponent);
      BattleSystem.DefendMalusPlayer = Number(BattleSystem.DefendMalusPlayer);
      LookUpCard(_loc1_.CardID).Activate();
   }
   if(IsGreenCard(_loc1_))
   {
      if(_loc1_.CardID == 302)
      {
         if(CurrentPlayer == TURN_PLAYER)
         {
            Player.LifePointReserve += 5;
         }
         else
         {
            Opponent.LifePointReserve += 5;
         }
      }
      if(_loc1_.CardID == 303)
      {
         BattleSystem.MalusOpponent = Number(BattleSystem.MalusOpponent);
         BattleSystem.MalusPlayer = Number(BattleSystem.MalusPlayer);
         BattleSystem.DefendMalusOpponent = Number(BattleSystem.DefendMalusOpponent);
         BattleSystem.DefendMalusPlayer = Number(BattleSystem.DefendMalusPlayer);
      }
      LookUpCard(_loc1_.CardID).Activate();
   }
   if(BattleSystem.SprklHelpEq || BattleSystem.blessingEq || BattleSystem.yellowManacle)
   {
      if(CurrentPlayer == TURN_PLAYER)
      {
         Player.LifePointReserve += BattleSystem.addLifePoint;
      }
      else
      {
         Opponent.LifePointReserve += BattleSystem.addLifePoint;
      }
      BattleSystem.addLifePoint = 0;
   }
   if(BattleSystem.giftOracleEq)
   {
      if(CurrentPlayer == TURN_PLAYER)
      {
         BattleSystem.addLifePoint = Player.LifePointDup - BattleSystem.PlayerHitPointTotal();
         if(BattleSystem.addLifePoint < 0)
         {
            BattleSystem.addLifePoint = 0;
         }
         Player.LifePointReserve += BattleSystem.addLifePoint;
      }
      else
      {
         BattleSystem.addLifePoint = Opponent.LifePointDup - BattleSystem.OpponentHitPointTotal();
         if(BattleSystem.addLifePoint < 0)
         {
            BattleSystem.addLifePoint = 0;
         }
         Opponent.LifePointReserve += BattleSystem.addLifePoint;
      }
      BattleSystem.addLifePoint = 0;
   }
   _loc1_.CardCloner.Show();
   if(_loc2_ != undefined)
   {
      CurrentPlayer = _loc3_;
   }
   statCurrentAttack.Update();
   statPlayerTotal.Update();
   statOpponentTotal.Update();
   broadcastMessage("onBattleSystemActivateCard");
   root.sfx.gotoAndPlay("CardActivation");
}
function GameOver()
{
   SetMode(MODE_GAMEOVER);
   Console.Write("<gameover>");
   statPlayerTotal.Update();
   statOpponentTotal.Update();
   if(IsWinner)
   {
      AnimPlayer.Avatar.gotoAndStop("WIN");
      root.sfx.gotoAndPlay("Win");
      VictoryPoint = LookUpMonster(Opponent.ID).VictoryPoint;
      Console.Write("<win>");
      Console.Write("<victory " + VictoryPoint + ">");
      WaitCallback = function()
      {
         clearInterval(intervalID);
         PopUpXP.gotoAndPlay("open");
      };
      intervalID = setInterval(Wait,1000);
   }
   else
   {
      root.sfx.gotoAndPlay("Loose");
      Console.Write("<loose>");
   }
}
