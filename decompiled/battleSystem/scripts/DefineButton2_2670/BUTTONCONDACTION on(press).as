on(press){
   BattleSystem.IsDraging = true;
   BattleSystem.HasMouseReleased = false;
   BattleSystem.DragedCard = _parent;
   BattleSystem.DragedCard.swapDepths(++BattleSystem.nextDepth);
   BattleSystem.DragedCard.startDrag();
}
