onClipEvent(load){
   this.onPress = function()
   {
      var _loc1_ = _parent;
      if(_loc1_.armorChange)
      {
         _loc1_.resetPerso();
      }
      _loc1_.saveInfoChar();
      root.updatePlayer();
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
