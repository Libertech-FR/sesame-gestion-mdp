<template>
  <div>
    <q-page class="window-height window-width row justify-center items-center">
      <q-card class="shadow-24 row" style="max-width: 800px;">
        <q-toolbar class="bg-primary text-white">
          <q-toolbar-title>Initialisation de votre compte</q-toolbar-title>
        </q-toolbar>
        <q-card-section class="col-lg-4 flex items-center mobile-hide">
          <q-img src="/logo.png" style="max-width: 100%;width:500px;"/>
        </q-card-section>
        <q-card-section class="col-lg-8  column">
          <input-new-password v-model="newpassword"
                              :min="passwordPolicies.len"
                              :min-upper="passwordPolicies.hasUpperCase"
                              :min-lower="passwordPolicies.hasLowerCase"
                              :min-number="passwordPolicies.hasNumbers"
                              :min-special="passwordPolicies.hasSpecialChars"
                              :min-entropy="passwordPolicies.minComplexity"
                              :entropy-bad="passwordPolicies.minComplexity"
                              :entropy-good="passwordPolicies.goodComplexity"
                              :check-pwned="passwordPolicies.checkPwned"
          >
          </input-new-password>
          <q-btn @click="envoi" :loading="loading" color="primary" style="width:100%" :disabled="enableValidation">
            Validez
          </q-btn>
        </q-card-section>
      </q-card>
      <q-dialog v-model="message">
        <q-card>
          <q-toolbar class=" text-white" :class="messageType">
            <q-toolbar-title>Message</q-toolbar-title>
          </q-toolbar>

          <q-card-section class="q-pt-none">
            <div class="col-lg-12" style="margin-top: 10px;">
              {{ messageText }}
            </div>
          </q-card-section>

          <q-card-actions align="right">
            <q-btn @click="doActionMessage" flat label="OK" color="primary" v-close-popup/>
          </q-card-actions>
        </q-card>
      </q-dialog>
    </q-page>
  </div>
</template>

<script setup>
import {computed, onMounted, ref} from "vue";
import { useRoute } from 'vue-router'
const loading = ref(false)
const route = useRoute()
const messageType = ref('bg-secondary')
const messageText = ref('')
const messageAction = ref('reloadPage')
const message = ref(false)
const newpassword = ref('')
const passwordPolicies = ref({
  bannedTime: 3600,
  checkPwned: true,
  goodComplexity: 60,
  hasLowerCase: 1,
  hasNumbers: 1,
  hasSpecialChars: 1,
  hasUpperCase: 1,
  len: 10,
  maxRetry: 10,
  minComplexity: 20,
  resetBySms: false,
  redirectUrl: ''
})

onMounted(async () => {
      const requestOptions = {method: 'GET'}
      let rep = await fetch('/management/passwd/getpolicies')
      if (rep.status === 200) {
        let response = await rep.json();
        passwordPolicies.value = response.data
      } else {
        messageAction.value = 'reloadPage'
        messageText.value = 'Une erreur c est produite : ' + rep.status
        messageType.value = 'bg-negative'
        message.value = true
      }
    }
)

const enableValidation = computed(() => {
  if (newpassword.value === '') {
    return true
  }
  return false
})

function envoi() {
  loading.value = true
  const requestOptions = {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({token: route.params.token,newPassword: newpassword.value})
  }
  fetch('/management/passwd/reset', requestOptions)
      .then(async response => {
        loading.value = false
        const isJson = response.headers.get('content-type')?.includes('application/json');
        const data = isJson && await response.json();
        console.log('status :' + data.status)
        // check for error response
        if (response.status === 200){
          messageAction.value = 'redirect'
          messageText.value = 'Votre mot de passe a été changé. Vous pouvez vous connecter'
          messageType.value = 'bg-secondary'
          message.value = true
        } else if (response.status === 400){
          messageAction.value = 'reloadPage'
          messageText.value = 'Erreur d\'authentification. Veuillez réessayer.'
          messageType.value = 'bg-negative'
          message.value = true
        }else{
          const error = (data && data.message) || response.status;
          return Promise.reject(error);
        }
      })
      .catch(error => {
        messageAction.value = 'reloadPage'
        messageText.value = 'Une erreur c est produite : ' + error
        messageType.value = 'bg-negative'
        message.value = true
        loading.value = false
        console.error('There was an error!', error);
      })
}
function doActionMessage() {
  if (messageAction.value === 'reloadPage') {
    window.location.reload()
  }
  if (messageAction.value === 'redirect') {
    window.location.replace(passwordPolicies.value.redirectUrl )
  }
}
</script>

<style scoped>

</style>