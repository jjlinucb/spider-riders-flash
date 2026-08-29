txtHigh.text = root.getInsName("txtHigh",root.parseKitVisual);
root.returnTopTen(this.ID);
drawHighScores = function(slArray)
{
   trace("drawHighScores");
   var _loc1_ = 0;
   var _loc2_;
   var _loc3_;
   while(_loc1_ < 10)
   {
      _loc2_ = String(slArray[_loc1_]);
      trace(_loc2_);
      if(_loc2_ != undefined)
      {
         _loc3_ = _loc2_.split("~");
         scorePanel["name" + _loc1_].text = _loc3_[1] + "\n";
         scorePanel["score" + _loc1_].text = _loc3_[2] + "\n";
      }
      else
      {
         scorePanel["name" + _loc1_].text = this["title" + _loc1_].text = "";
         scorePanel["score" + _loc1_].text += _loc3_[2] + "\n";
      }
      _loc1_ = _loc1_ + 1;
   }
};
