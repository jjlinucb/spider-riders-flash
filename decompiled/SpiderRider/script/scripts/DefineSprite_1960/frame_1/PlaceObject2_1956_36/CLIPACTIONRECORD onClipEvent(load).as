onClipEvent(load){
   this.onPress = function()
   {
      var _loc1_ = _parent;
      if(_loc1_.volumeWindow._currentframe == 1)
      {
         _loc1_.volumeWindow.drawWindow();
      }
      else
      {
         _loc1_.volumeWindow.closeWindow();
      }
      root.sfx.gotoAndPlay("clic");
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
   };
   this.onReleaseOutside = function()
   {
      this.gotoAndStop("up");
   };
}
