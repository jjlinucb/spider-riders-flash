txtMiniGTitle.text = root.getInsName("txtMiniGTitle",root.parseKitVisual);
txtStatus.text = root.getInsName("txtStatus",root.parseKitVisual);
txtNames.text = root.getInsName("txtNames",root.parseKitVisual);
txtPts.text = root.getInsName("txtPts",root.parseKitVisual);
var _loc0_;
switch(this.gameID)
{
   case 1:
      clipTitle.gotoAndStop(this.gameID);
      var _temp_2 = clipTitle.txtMiniG1;
      var _temp_1 = "text";
      clipTitle.txtMiniG1S.text = _loc0_ = root.getInsName("txtMiniG1",root.parseKitVisual);
      _temp_2[_temp_1] = _loc0_;
      break;
   case 2:
      clipTitle.gotoAndStop(this.gameID);
      var _temp_4 = clipTitle.txtMiniG2;
      var _temp_3 = "text";
      clipTitle.txtMiniG2S.text = _loc0_ = root.getInsName("txtMiniG2",root.parseKitVisual);
      _temp_4[_temp_3] = _loc0_;
      break;
   case 3:
      clipTitle.gotoAndStop(this.gameID);
      var _temp_6 = clipTitle.txtMiniG3;
      var _temp_5 = "text";
      clipTitle.txtMiniG3S.text = _loc0_ = root.getInsName("txtMiniG3",root.parseKitVisual);
      _temp_6[_temp_5] = _loc0_;
      break;
   case 4:
      clipTitle.gotoAndStop(this.gameID);
      var _temp_8 = clipTitle.txtMiniG4;
      var _temp_7 = "text";
      clipTitle.txtMiniG4S.text = _loc0_ = root.getInsName("txtMiniG4",root.parseKitVisual);
      _temp_8[_temp_7] = _loc0_;
      break;
   case 5:
      clipTitle.gotoAndStop(this.gameID);
      var _temp_10 = clipTitle.txtMiniG5;
      var _temp_9 = "text";
      clipTitle.txtMiniG5S.text = _loc0_ = root.getInsName("txtMiniG5",root.parseKitVisual);
      _temp_10[_temp_9] = _loc0_;
      break;
   case 6:
      clipTitle.gotoAndStop(this.gameID);
      var _temp_12 = clipTitle.txtMiniG6;
      var _temp_11 = "text";
      clipTitle.txtMiniG6S.text = _loc0_ = root.getInsName("txtMiniG6",root.parseKitVisual);
      _temp_12[_temp_11] = _loc0_;
      break;
   case 7:
      clipTitle.gotoAndStop(this.gameID);
      var _temp_14 = clipTitle.txtMiniG7;
      var _temp_13 = "text";
      clipTitle.txtMiniG7S.text = _loc0_ = root.getInsName("txtMiniG7",root.parseKitVisual);
      _temp_14[_temp_13] = _loc0_;
      break;
   default:
      var _temp_16 = clipTitle.txtMiniG1;
      var _temp_15 = "text";
      clipTitle.txtMiniG1s.text = _loc0_ = root.getInsName("txtError",root.parseKitVisual);
      _temp_16[_temp_15] = _loc0_;
}
