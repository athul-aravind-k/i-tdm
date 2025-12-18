<script setup>
import { ref } from 'vue'

/* =========================
   Props / Emits
========================= */
const props = defineProps({
  payload: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['change'])

/* =========================
   State
========================= */
const password = ref('')
const error = ref(false)

const selectedMap = props.payload.map

/* =========================
   FiveM-safe helper
========================= */
function getResourceName() {
  return window.GetParentResourceName
    ? GetParentResourceName()
    : 'dev'
}

/* =========================
   Actions
========================= */
function createTDM() {
  error.value = false

  fetch(`https://${getResourceName()}/createTDM`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      map: selectedMap,
      password: password.value.trim()
    })
  })
}

function goBack() {
  emit('change', 'create')
}
</script>

<template>
  <div class="create-container">
    <!-- BACK -->
    <h2 class="close" @click="goBack">
      &lt; Back
    </h2>

    <!-- CREATE PASSWORD -->
    <div class="tdm-create-pass">
      <div class="tdm-create-pass-form">
        <h2>Create Match</h2>

        <div class="tdm-private-pass">
          <label class="tdm-password-label">
            <span>Password</span>

            <input
              v-model="password"
              placeholder="Enter password"
              type="password"
            />

            <span
              v-if="error"
              class="tdm-invalid-password"
            >
              Invalid password
            </span>
          </label>
        </div>

        <span>
          *Leave password empty to create a public lobby.
        </span>
      </div>

      <button
        id="create-tdm-pass"
        class="tdm-create-pass-btn"
        @click="createTDM"
      >
        Start
      </button>
    </div>
  </div>
</template>
