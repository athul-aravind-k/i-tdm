<script setup>
import { ArrowLeft, Users, Crosshair } from 'lucide-vue-next'

const emit = defineEmits(['change'])
function getResourceName() {
  return window.GetParentResourceName
    ? GetParentResourceName()
    : 'dev'
}

function joinDM() {
  fetch(`https://${getResourceName()}/get-active-matches`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  })
    .then(res => res.json())
    .then(matches => {
      emit('change', {
        screen: 'activeTdms',
        payload: {
          mode: 'deathmatch',
          matches
        }
      })
    })
}

function joinTDM() {
  fetch(`https://${getResourceName()}/get-active-matches-tdm`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  })
    .then(res => res.json())
    .then(matches => {
      emit('change', {
        screen: 'activeTdms',
        payload: {
          mode: 'tdm',
          matches
        }
      })
    })
}

function goBack() {
  emit('change','main')
}

</script>

<template>
  <div class="gm-root">
    <!-- Background -->
    <div class="gm-bg">
      <img
        src="/assets/bg/modes.png"
        alt="Background"
      />
      <div class="gm-overlay"></div>
    </div>

    <div class="gm-content">
      <!-- Header -->
      <div class="gm-header">
        <button class="gm-back" @click="goBack">
          <ArrowLeft />
          <span>Back</span>
        </button>

        <h1 class="gm-title gm-anim-down">SELECT MODE TO JOIN</h1>

        <div class="gm-spacer"></div>
      </div>

      <!-- Modes -->
      <div class="gm-center">
        <div class="gm-grid">
          <!-- TEAM DEATHMATCH -->
          <div
            class="gm-card gm-anim-scale delay-1 blue"
            @click="joinTDM"
          >
            <div class="gm-image">
              <img
                src="/assets/bg/team.png"
                alt="Team Deathmatch"
              />
              <div class="gm-gradient"></div>

              <div class="gm-icon blue">
                <Users />
              </div>
            </div>

            <div class="gm-info">
              <h2>TEAM DEATHMATCH</h2>
              <p>Team-based combat with coordinated strategy</p>

              <button class="gm-btn blue">SELECT</button>
            </div>
          </div>

          <!-- DEATHMATCH -->
          <div
            class="gm-card gm-anim-scale delay-2 red"
            @click="joinDM"
          >
            <div class="gm-image">
              <img
                src="/assets/bg/solo.png"
                alt="Deathmatch"
              />
              <div class="gm-gradient"></div>

              <div class="gm-icon red">
                <Crosshair />
              </div>
            </div>

            <div class="gm-info">
              <h2>DEATHMATCH</h2>
              <p>Free-for-all combat, every player for themselves</p>

              <button class="gm-btn red">SELECT</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ===== ROOT ===== */
.gm-root {
  width: 100%;
  height: 100vh;
  background: black;
  font-family: Arial, Helvetica, sans-serif;
  overflow: hidden;
}

/* ===== BACKGROUND ===== */
.gm-bg {
  position: absolute;
  inset: 0;
}

.gm-bg img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.gm-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    to bottom,
    rgba(0, 0, 0, 0.6),
    rgba(0, 0, 0, 0.4),
    rgba(0, 0, 0, 0.8)
  );
}

/* ===== CONTENT ===== */
.gm-content {
  position: relative;
  z-index: 2;
  display: flex;
  flex-direction: column;
  padding: 32px;
}

/* ===== HEADER ===== */
.gm-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 48px;
}

.gm-back {
  display: flex;
  align-items: center;
  gap: 8px;
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.8);
  cursor: pointer;
}

.gm-back svg {
  width: 20px;
  height: 20px;
}

.gm-back:hover {
  color: white;
}

.gm-title {
  color: white;
  font-size: 36px;
  letter-spacing: 4px;
  text-shadow: 0 0 20px rgba(0, 0, 0, 0.8);
}

.gm-spacer {
  width: 80px;
}

/* ===== CENTER ===== */
.gm-center {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* ===== GRID ===== */
.gm-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 32px;
  max-width: 1200px;
  width: 100%;
}

/* ===== CARD ===== */
.gm-card {
  cursor: pointer;
  border: 2px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  overflow: hidden;
  transition: all 0.3s ease;
}

.gm-card:hover {
  transform: scale(1.02);
}

.gm-card.blue:hover {
  border-color: rgba(59, 130, 246, 0.6);
}

.gm-card.red:hover {
  border-color: rgba(239, 68, 68, 0.6);
}

/* ===== IMAGE ===== */
.gm-image {
  position: relative;
  aspect-ratio: 16 / 9;
}

.gm-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.gm-gradient {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    to top,
    rgba(0, 0, 0, 0.9),
    rgba(0, 0, 0, 0.5),
    transparent
  );
}

/* ===== ICON ===== */
.gm-icon {
  position: absolute;
  top: 16px;
  right: 16px;
  width: 64px;
  height: 64px;
  border-radius: 8px;
  backdrop-blur: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
}

.gm-icon svg {
  width: 32px;
  height: 32px;
}

.gm-icon.blue {
  background: rgba(59, 130, 246, 0.3);
  border: 1px solid rgba(59, 130, 246, 0.5);
  color: #60a5fa;
}

.gm-icon.red {
  background: rgba(239, 68, 68, 0.3);
  border: 1px solid rgba(239, 68, 68, 0.5);
  color: #f87171;
}

/* ===== INFO ===== */
.gm-info {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 24px;
}

.gm-info h2 {
  color: white;
  font-size: 28px;
  margin: 0 0 8px;
  letter-spacing: 1px;
}

.gm-info p {
  color: #ccc;
  margin-bottom: 16px;
}

/* ===== BUTTON ===== */
.gm-btn {
  width: 100%;
  padding: 12px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  color: white;
  cursor: pointer;
  transition: background 0.2s ease;
}

.gm-btn.blue {
  background: #3b82f6;
}

.gm-btn.blue:hover {
  background: #2563eb;
}

.gm-btn.red {
  background: #ef4444;
}

.gm-btn.red:hover {
  background: #dc2626;
}

/* ===== ANIMATIONS ===== */
@keyframes gm-scale {
  from {
    opacity: 0;
    transform: scale(0.9);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

@keyframes gm-down {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.gm-anim-scale {
  animation: gm-scale 0.5s ease forwards;
}

.gm-anim-down {
  animation: gm-down 0.6s ease forwards;
}

/* ===== DELAYS ===== */
.delay-1 {
  animation-delay: 0.2s;
}

.delay-2 {
  animation-delay: 0.3s;
}
</style>
