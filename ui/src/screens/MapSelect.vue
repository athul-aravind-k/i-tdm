<script setup>
import { ref, watch } from 'vue'
import { ArrowLeft, Check } from 'lucide-vue-next'

const props = defineProps({
  payload: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['change', 'close'])

const selectedMap = ref(null)
const maps = ref(null)
const isTdm = props.payload.isTdm

watch(
  () => props.payload,
  (newPayload) => {
    if (!newPayload) return
    maps.value = newPayload.maps
  },
  { immediate: true }
)

function getResourceName() {
  return window.GetParentResourceName
    ? GetParentResourceName()
    : 'dev'
}

function confirmSelection() {
  if (!selectedMap.value) return

  // DM
  if (!isTdm) {
    fetch(`https://${getResourceName()}/startDeathMatch`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        selectedMap: selectedMap.value
      })
    })

    emit('close')
    return
  }

  // TDM → go to password screen
  emit('change', {
    screen: 'tdmPassword',
    payload: { map: selectedMap.value }
  })
}

function goBack() {
  emit('change', 'create')
}
</script>

<template>
  <div class="ms-root">
    <div class="ms-bg">
      <!-- <img
        src="https://images.unsplash.com/photo-1562281302-809108fd533c"
        alt="Background"
      /> -->
      <div class="ms-overlay"></div>
    </div>

    <div class="ms-content">
      <div class="ms-header">
        <button class="ms-back" @click="goBack">
          <ArrowLeft />
          <span>Back</span>
        </button>

        <h1 class="ms-title ms-anim-down">SELECT MAP</h1>

        <div class="ms-spacer"></div>
      </div>

      <div class="ms-center">
        <div class="ms-container">
          <div class="ms-scroll">
            <div class="ms-grid">
              <div v-for="(map, index) in maps" :key="map.name" class="ms-card ms-anim-scale"
                :style="{ animationDelay: `${index * 0.05}s` }" :class="selectedMap === map.name ? 'active' : ''"
                @click="selectedMap = map.name">
                <div class="ms-thumb">
                  <img :src="`assets/maps/${map.image}`" :alt="map.name" />

                  <div class="ms-dim"></div>

                  <div v-if="selectedMap === map.name" class="ms-check">
                    <Check />
                  </div>

                  <div class="ms-label">
                    {{ map.label }}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="ms-confirm">
            <button class="ms-confirm-btn" :class="selectedMap ? 'enabled' : 'disabled'" :disabled="!selectedMap"
              @click="confirmSelection">
              CONFIRM
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.ms-root {
  width: 100%;
  height: 100vh;
  background: radial-gradient(circle at top, #111, #000);
  font-family: Arial, Helvetica, sans-serif;
  overflow: hidden;
}

.ms-bg {
  position: absolute;
  inset: 0;
}

.ms-bg img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.ms-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(to bottom,
      rgba(0, 0, 0, 0.7),
      rgba(0, 0, 0, 0.5),
      rgba(0, 0, 0, 0.8));
}

.ms-content {
  position: relative;
  z-index: 2;
  display: flex;
  flex-direction: column;
  padding: 32px;
}

.ms-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 32px;
}

.ms-back {
  display: flex;
  align-items: center;
  gap: 8px;
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.8);
  cursor: pointer;
}

.ms-back svg {
  width: 20px;
  height: 20px;
}

.ms-back:hover {
  color: white;
}

.ms-title {
  color: white;
  font-size: 36px;
  letter-spacing: 4px;
  text-shadow: 0 0 20px rgba(0, 0, 0, 0.8);
}

.ms-spacer {
  width: 80px;
}

.ms-center {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.ms-container {
  width: 100%;
  max-width: 1100px;
}

.ms-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-bottom: 32px;
}

.ms-card {
  cursor: pointer;
  border: 2px solid rgba(255, 255, 255, 0.2);
  overflow: hidden;
  border-radius: 6px;
  transition: all 0.3s ease;
}

.ms-card:hover {
  border-color: rgba(255, 255, 255, 0.4);
  transform: scale(1.03);
}

.ms-card.active {
  border-color: #22c55e;
  box-shadow: 0 0 20px rgba(34, 197, 94, 0.5);
  transform: scale(1.05);
}

.ms-thumb {
  position: relative;
  aspect-ratio: 16 / 9;
}

.ms-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.ms-dim {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.3);
  transition: background 0.3s ease;
}

.ms-card:hover .ms-dim {
  background: rgba(0, 0, 0, 0.1);
}

.ms-check {
  position: absolute;
  top: 12px;
  right: 12px;
  background: #22c55e;
  border-radius: 50%;
  padding: 6px;
}

.ms-check svg {
  width: 20px;
  height: 20px;
  color: white;
}

.ms-label {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  padding: 12px;
  font-size: 14px;
  color: white;
  background: linear-gradient(to top,
      rgba(0, 0, 0, 0.9),
      rgba(0, 0, 0, 0.7),
      transparent);
}

.ms-confirm {
  display: flex;
  justify-content: center;
}

.ms-confirm-btn {
  padding: 16px 64px;
  border-radius: 6px;
  border: none;
  font-size: 16px;
  transition: all 0.2s ease;
  margin-top: 10px;
}

.ms-confirm-btn.enabled {
  background: #22c55e;
  color: white;
  cursor: pointer;
}

.ms-confirm-btn.enabled:hover {
  background: #16a34a;
  transform: scale(1.05);
}

.ms-confirm-btn.disabled {
  background: rgba(75, 85, 99, 0.5);
  color: #777;
  cursor: not-allowed;
}

.ms-scroll {
  max-height: 45vh;
  overflow-y: auto;
  padding-right: 8px;
}

.ms-scroll {
  overflow-x: visible;
}

.ms-scroll::-webkit-scrollbar {
  width: 6px;
}

.ms-scroll::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.05);
}

.ms-scroll::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.25);
  border-radius: 4px;
}

.ms-scroll::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.4);
}


/* ===== ANIMATIONS ===== */
@keyframes ms-scale {
  from {
    opacity: 0;
    transform: scale(0.9);
  }

  to {
    opacity: 1;
    transform: scale(1);
  }
}

@keyframes ms-down {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.ms-anim-scale {
  animation: ms-scale 0.4s ease forwards;
}

.ms-anim-down {
  animation: ms-down 0.6s ease forwards;
}
</style>
