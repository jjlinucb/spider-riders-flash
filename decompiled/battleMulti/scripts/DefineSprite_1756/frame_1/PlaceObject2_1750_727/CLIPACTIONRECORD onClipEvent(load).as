onClipEvent(load){
   this.onPress = function()
   {
      root.gameSO.send("playerDisconnect");
   };
   this.txt.text = "J\'écoute";
}
