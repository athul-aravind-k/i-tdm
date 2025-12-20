<script setup>
import { Plus, Users, Trophy } from "lucide-vue-next";

const emit = defineEmits(['change'])
</script>

<template>
  <div class="menu-root">
    <!-- Background -->
    <div class="background">
      <img
        src="/assets/bg/main.png"
        alt="Background"
      />
      <div class="overlay"></div>
    </div>

    <!-- Content -->
    <div class="content">
      <div class="panel animate-panel">
        <!-- <h1 class="title animate-title">I TDM</h1> -->

        <div class="menu">
          <button class="menu-btn green animate-left delay-1" @click="emit('change', 'create')">
            <div class="icon-box green">
              <Plus />
            </div>
            <div class="menu-item-text">
              <h2>Create Lobby</h2>
              <p>Start a new match and invite players</p>
            </div>
          </button>

          <button class="menu-btn blue animate-left delay-2" @click="emit('change', 'join')">
            <div class="icon-box blue">
              <Users />
            </div>
            <div class="menu-item-text">
              <h2>Join Game</h2>
              <p>Browse and join active matches</p>
            </div>
          </button>

          <button class="menu-btn yellow animate-left delay-3" @click="emit('change', 'leaderboard')">
            <div class="icon-box yellow">
              <Trophy />
            </div>
            <div class="menu-item-text">
              <h2>Leaderboard</h2>
              <p>View top players and rankings</p>
            </div>
          </button>
        </div>

        <p class="hint fade-in delay-4">Press ESC to return</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ROOT */
.menu-root {
  width: 100%;
  height: 100vh;
  overflow: hidden;
  background: radial-gradient(circle at top, #111, #000);
  font-family: Arial, Helvetica, sans-serif;
}

/* BACKGROUND */
.background {
  position: absolute;
  inset: 0;
}

.background img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    to bottom,
    rgba(0, 0, 0, 0.6),
    rgba(0, 0, 0, 0.4),
    rgba(0, 0, 0, 0.8)
  );
}

/* CONTENT */
.content {
  position: relative;
  z-index: 10;
  display: flex;
  height: 70%;
  align-items: center;
  justify-content: center;
}

.menu-item-text {
  display: flex;
  flex-direction: column;
  align-items: flex-start;

  p{
    margin-block-start: 0 !important;
    margin-block-end: 0 !important;
  }
}

.panel {
  width: 100%;
  max-width: 700px;
  padding: 40px;
}

/* TITLE */
.title {
  color: white;
  font-size: 64px;
  text-align: center;
  letter-spacing: 4px;
  margin-bottom: 60px;
  text-shadow: 0 0 20px rgba(0, 0, 0, 0.8);
}

/* MENU */
.menu {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.menu-btn {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 24px;
  background: rgba(0, 0, 0, 0.6);
  border: none;
  border-left: 4px solid;
  color: white;
  cursor: pointer;
  transition: transform 0.3s ease, background 0.3s ease;
}

.menu-btn:hover {
  transform: translateX(10px);
  background: rgba(255, 255, 255, 0.1);
}

.menu-btn h2 {
  font-size: 24px;
  margin: 0 0 4px;
}

.menu-btn p {
  font-size: 14px;
  color: #aaa;
}

/* ICONS */
.icon-box {
  width: 48px;
  height: 48px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.icon-box svg {
  width: 24px;
  height: 24px;
}

/* COLORS */
.green {
  border-color: #22c55e;
}
.green .icon-box {
  background: rgba(34, 197, 94, 0.2);
}
.green svg {
  color: #22c55e;
}

.blue {
  border-color: #3b82f6;
}
.blue .icon-box {
  background: rgba(59, 130, 246, 0.2);
}
.blue svg {
  color: #3b82f6;
}

.yellow {
  border-color: #eab308;
}
.yellow .icon-box {
  background: rgba(234, 179, 8, 0.2);
}
.yellow svg {
  color: #eab308;
}

/* FOOTER */
.hint {
  margin-top: 48px;
  text-align: center;
  color: #777;
  font-size: 14px;
}

/* ANIMATIONS */
@keyframes fadeUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes fadeDown {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes slideLeft {
  from {
    opacity: 0;
    transform: translateX(-50px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

@keyframes fade {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.animate-panel {
  animation: fadeUp 0.6s ease forwards;
}

.animate-title {
  animation: fadeDown 0.6s ease forwards;
}

.animate-left {
  animation: slideLeft 0.6s ease forwards;
}

.fade-in {
  animation: fade 0.6s ease forwards;
}

/* DELAYS */
.delay-1 {
  animation-delay: 0.3s;
}
.delay-2 {
  animation-delay: 0.4s;
}
.delay-3 {
  animation-delay: 0.5s;
}
.delay-4 {
  animation-delay: 0.8s;
}
</style>
