onClipEvent(load){
   this.onPress = function()
   {
      var _loc1_ = _parent;
      this.gotoAndStop("down");
      if(_loc1_.spiderChange || _loc1_.charChange)
      {
         endFct = function()
         {
            var _loc1_ = _parent;
            root.showTextSheet = false;
            if(_loc1_.spiderChange)
            {
               _loc1_.spiderChange = false;
            }
            if(_loc1_.charChange)
            {
               _loc1_.charChange = false;
            }
            if(root.inCamp == true)
            {
               root.charWindow.closeWindow();
            }
            else
            {
               _loc1_.popUp.gotoAndPlay("show");
            }
         };
         if(_loc1_.charChange)
         {
            root.askWindow.drawWindow([root.getInsName("txtNotSaveChar",root.parseKitSheets)],endFct);
         }
         else
         {
            root.askWindow.drawWindow([root.getInsName("txtNotSaveSpi",root.parseKitSheets)],endFct);
         }
      }
      else if(root.inCamp == true)
      {
         root.charWindow.closeWindow();
      }
      else
      {
         _loc1_.popUp.gotoAndPlay("show");
      }
      root.sfx.gotoAndPlay("clic2");
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
