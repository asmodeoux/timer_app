abstract class TimerModel {
  Stream<bool> get timerIsActive;
  Stream<String> get timeTillEndReadable;
  Stream<bool> get timeIsOver;

  void changeTimerState();
}