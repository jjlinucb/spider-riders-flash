onClipEvent(load){
   this.onPress = function()
   {
      var _loc1_ = _parent;
      this.gotoAndStop("down");
      var _loc2_;
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
            var _loc2_;
            if(root.inWorld == true || root.inCamp == true)
            {
               _loc2_ = function()
               {
                  root.askWindow.closeWindow();
                  root.upPanel.endFct = function()
                  {
                     root.gotoAndStop("level1");
                     root.charWindow.closeWindow();
                  };
                  root.upPanel.gotoAndPlay("close");
                  root.downPanel.gotoAndPlay("close");
               };
               root.askWindow.drawWindow([root.getInsName("txtMovMissions",root.parseKitSheets)],_loc2_);
            }
            else
            {
               root.upPanel.endFct = function()
               {
                  if(root.inWorld == undefined)
                  {
                     root.gotoAndStop("level1");
                  }
                  root.charWindow.closeWindow();
               };
               root.askWindow.closeWindow();
               root.upPanel.gotoAndPlay("close");
               root.downPanel.gotoAndPlay("close");
            }
            delete endFct;
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
      else if(root.inWorld == true || root.inCamp == true)
      {
         _loc2_ = function()
         {
            root.showTextSheet = false;
            root.upPanel.endFct = function()
            {
               root.gotoAndStop("level1");
               root.charWindow.closeWindow();
            };
            root.askWindow.closeWindow();
            root.upPanel.gotoAndPlay("close");
            root.downPanel.gotoAndPlay("close");
         };
         root.askWindow.drawWindow([root.getInsName("txtMovMissions",root.parseKitSheets)],_loc2_);
      }
      else
      {
         root.showTextSheet = false;
         root.upPanel.endFct = function()
         {
            if(root.inWorld == undefined)
            {
               root.gotoAndStop("level1");
            }
            root.charWindow.closeWindow();
         };
         root.askWindow.closeWindow();
         root.upPanel.gotoAndPlay("close");
         root.downPanel.gotoAndPlay("close");
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
