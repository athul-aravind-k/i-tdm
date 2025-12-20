<script setup>
import { ArrowLeft, Globe, Lock } from "lucide-vue-next";
import { ref } from 'vue'

const props = defineProps({
  payload: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['change'])

const password = ref('')
const isPrivate = ref(false)

const selectedMap = props.payload.map

function getResourceName() {
  return window.GetParentResourceName
    ? GetParentResourceName()
    : 'dev'
}

function createTDM() {
  fetch(`https://${getResourceName()}/createTDM`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: selectedMap,
      password: isPrivate.value ? password.value.trim():''
    })
  })
}

function goBack() {
  emit('change', 'create')
}

function selectPublic() {
  isPrivate.value = false;
  password.value = "";
}

function selectPrivate() {
  isPrivate.value = true;
}

function confirm() {
  if (isPrivate.value && !password.value) return;
  createTDM()
}

</script>

<template>
  <div class="ls-root">
    <!-- Background -->
    <div class="ls-bg">
      <img
        src="https://images.unsplash.com/photo-1741550005120-6e8bfab52992"
        alt="Background"
      />
      <div class="ls-overlay"></div>
    </div>

    <div class="ls-content">
      <!-- Header -->
      <div class="ls-header">
        <button class="ls-back" @click="goBack">
          <ArrowLeft />
          <span>Back</span>
        </button>

        <h1 class="ls-title ls-anim-down">LOBBY TYPE</h1>

        <div class="ls-spacer"></div>
      </div>

      <!-- Options -->
      <div class="ls-center">
        <div class="ls-panel">
          <!-- PUBLIC -->
          <div
            class="ls-option ls-anim-left delay-1"
            :class="!isPrivate ? 'active-green' : 'inactive'"
            @click="selectPublic"
          >
            <div class="ls-option-inner">
              <div class="ls-icon green">
                <Globe />
              </div>

              <div class="ls-text">
                <h2>PUBLIC LOBBY</h2>
                <p>Anyone can find and join your match</p>
              </div>

              <div v-if="!isPrivate" class="ls-dot green"></div>
            </div>
          </div>

          <!-- PRIVATE -->
          <div
            class="ls-option ls-anim-left delay-2"
            :class="isPrivate ? 'active-orange' : 'inactive'"
            @click="selectPrivate"
          >
            <div class="ls-option-inner">
              <div class="ls-icon orange">
                <Lock />
              </div>

              <div class="ls-text">
                <h2>PRIVATE LOBBY</h2>
                <p>Password required to join</p>

                <div
                  v-if="isPrivate"
                  class="ls-password ls-anim-expand"
                  @click.stop
                >
                  <input
                    type="password"
                    placeholder="Enter password"
                    v-model="password"
                  />
                </div>
              </div>

              <div v-if="isPrivate" class="ls-dot orange"></div>
            </div>
          </div>

          <!-- CONFIRM -->
          <div class="ls-confirm">
            <button
              :disabled="isPrivate && !password"
              @click="confirm"
              class="ls-confirm-btn"
              :class="(!isPrivate || password.length) ? 'enabled' : 'disabled'"
            >
              CREATE LOBBY
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ===== ROOT ===== */
.ls-root {
  width: 100%;
  height: 100vh;
  background: radial-gradient(circle at top, #111, #000);
  font-family: Arial, Helvetica, sans-serif;
  overflow: hidden;
}

/* ===== BACKGROUND ===== */
.ls-bg {
  position: absolute;
  inset: 0;
}

.ls-bg img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.ls-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    to bottom,
    rgba(0, 0, 0, 0.7),
    rgba(0, 0, 0, 0.5),
    rgba(0, 0, 0, 0.8)
  );
}

/* ===== CONTENT ===== */
.ls-content {
  position: relative;
  z-index: 2;
  display: flex;
  flex-direction: column;
  padding: 32px;
}

/* ===== HEADER ===== */
.ls-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 48px;
}

.ls-back {
  display: flex;
  align-items: center;
  gap: 8px;
  color: rgba(255, 255, 255, 0.8);
  background: none;
  border: none;
  cursor: pointer;
}

.ls-back svg {
  width: 20px;
  height: 20px;
}

.ls-back:hover {
  color: white;
}

.ls-title {
  color: white;
  font-size: 36px;
  letter-spacing: 4px;
  text-shadow: 0 0 20px rgba(0, 0, 0, 0.8);
}

.ls-spacer {
  width: 80px;
}

/* ===== CENTER ===== */
.ls-center {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.ls-panel {
  width: 100%;
  max-width: 720px;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

/* ===== OPTIONS ===== */
.ls-option {
  padding: 32px;
  border: 2px solid rgba(255, 255, 255, 0.2);
  background: rgba(0, 0, 0, 0.4);
  cursor: pointer;
  transition: all 0.3s ease;
}

.ls-option:hover {
  transform: translateX(10px);
}

.ls-option-inner {
  display: flex;
  gap: 24px;
  align-items: center;
}

.ls-text {
  flex: 1;
}

.ls-dot {
  flex-shrink: 0;
  align-self: self-start;
}

.ls-text h2 {
  color: white;
  margin: 0 0 8px;
  font-size: 24px;
}

.ls-text p {
  color: #aaa;
  font-size: 14px;
}

/* ===== ICON ===== */
.ls-icon {
  width: 64px;
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
}

.ls-icon svg {
  width: 32px;
  height: 32px;
}

.green {
  background: rgba(34, 197, 94, 0.2);
  color: #22c55e;
}

.orange {
  background: rgba(249, 115, 22, 0.2);
  color: #f97316;
}

/* ===== ACTIVE STATES ===== */
.active-green {
  border-color: #22c55e;
  background: rgba(34, 197, 94, 0.1);
}

.active-orange {
  border-color: #f97316;
  background: rgba(249, 115, 22, 0.1);
}

.inactive:hover {
  border-color: rgba(255, 255, 255, 0.4);
}

/* ===== DOT ===== */
.ls-dot {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.ls-dot::after {
  content: "";
  width: 8px;
  height: 8px;
  background: white;
  border-radius: 50%;
}

/* ===== PASSWORD ===== */
.ls-password {
  margin-top: 16px;
}

.ls-password input {
  width: 100%;
  padding: 12px;
  background: rgba(0, 0, 0, 0.6);
  border: 1px solid rgba(249, 115, 22, 0.5);
  color: white;
  outline: none;
}

/* ===== CONFIRM ===== */
.ls-confirm {
  display: flex;
  justify-content: center;
  padding-top: 32px;
}

.ls-confirm-btn {
  padding: 16px 64px;
  border-radius: 6px;
  border: none;
  font-size: 16px;
  transition: all 0.2s ease;
}

.enabled {
  background: #22c55e;
  color: white;
  cursor: pointer;
}

.enabled:hover {
  background: #16a34a;
  transform: scale(1.05);
}

.disabled {
  background: rgba(75, 85, 99, 0.5);
  color: #777;
  cursor: not-allowed;
}

/* ===== ANIMATIONS ===== */
@keyframes ls-left {
  from {
    opacity: 0;
    transform: translateX(-50px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

@keyframes ls-down {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes ls-expand {
  from {
    opacity: 0;
    max-height: 0;
  }
  to {
    opacity: 1;
    max-height: 200px;
  }
}

.ls-anim-left {
  animation: ls-left 0.6s ease forwards;
}

.ls-anim-down {
  animation: ls-down 0.6s ease forwards;
}

.ls-anim-expand {
  animation: ls-expand 0.3s ease forwards;
}

/* ===== DELAYS ===== */
.delay-1 {
  animation-delay: 0.2s;
}
.delay-2 {
  animation-delay: 0.3s;
}
</style>
