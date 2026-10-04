class SoundManager {
  SoundManager._();

  static final SoundManager instance = SoundManager._();

  bool muted = false;

  void toggleMuted() {
    muted = !muted;
  }

  void playChomp() {}

  void playPower() {}

  void playEatGhost() {}

  void playDeath() {}

  void playLevelComplete() {}
}
