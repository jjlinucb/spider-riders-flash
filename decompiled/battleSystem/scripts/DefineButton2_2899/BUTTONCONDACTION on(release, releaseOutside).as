on(release, releaseOutside){
   anim.gotoAndStop("RELEASED");
   if(BattleSystem.IsFirstBattle)
   {
      if(root.inWorld != true && root.playerStats.mission < 1)
      {
         BattleSystem.IsFirstBattle = false;
         BattleSystem.Tutorial.gotoAndPlay("attackDone");
      }
   }
   else if(_parent.btnDicePlayer.intTutorial != undefined)
   {
      if(BattleSystem.Tutorial._currentframe > 150)
      {
         if(root.inWorld != true && root.playerStats.mission < 1)
         {
            BattleSystem.Tutorial.gotoAndPlay("attackDone");
         }
      }
   }
   clearInterval(_parent.btnDicePlayer.intTutorial);
   BattleSystem.CallbackButtonAction();
}
