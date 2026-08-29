onClipEvent(load){
   this.onPress = function()
   {
      this.gotoAndStop("down");
      root.sfx.gotoAndPlay("ButtonPressed");
   };
   this.onRollOver = function()
   {
      this.gotoAndStop("over");
   };
   this.onRollOut = function()
   {
      this.gotoAndStop("up");
   };
   this.onRelease = function()
   {
      this.gotoAndStop("up");
      endFct = function()
      {
         root.askWindow.closeWindow();
         BattleSystem.Retreat();
         delete endFct;
      };
      root.askWindow.drawWindow([root.getInsName("btnRetreat",root.parseKitBSystem)],endFct);
   };
   this.onReleaseOutside = function()
   {
      this.gotoAndStop("up");
   };
}
