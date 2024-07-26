<template>

  <q-card class="shadow-24 row" style="max-width: 800px;">
    <q-toolbar class="bg-primary text-white">
      <q-toolbar-title>Gestion de votre accès</q-toolbar-title>
    </q-toolbar>
    <q-card-section class="col-lg-4 flex items-center mobile-hide">
      <q-img src="/logo.png" style="max-width: 100%;width:500px;"/>
    </q-card-section>
    <q-card-section class="col-ms-8  column">
      <div class="q-pa-md row-md">
        <q-btn-toggle
          v-model="action"
          @click="resetData()"
          spread
          no-caps
          rounded
          unelevated
          toggle-color="primary"
          color="white"
          text-color="primary"
          :options="[
          {label: 'Changer votre mot de passe', value: 'change'},
          {label: 'Reinitialiser votre mot de passe', value: 'reset'}
        ]"
        />
      </div>
      <div v-show="action == 'change'" class="row-md">
        <q-input v-model="username" label="Utilisateur" type="text"></q-input>
        <q-input v-model="oldpassword" label="Mot de passe" type="password"></q-input>
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
      </div>
      <div v-show="action == 'reset'" class="row-md">
        <div class="q-pa-md row-md">
          <q-btn-toggle
            @click="actionResetRenit()"
            v-model="actionReset"
            spread
            no-caps
            rounded
            unelevated
            toggle-color="warning"
            color="white"
            text-color="primary"
            :options="optionsReset()"
          />
        </div>
        <q-input v-model="username" label="Utilisateur" type="text"></q-input>
      </div>
      <div v-show="action !== ''" class="row-md" style="margin-top: 30px;">

        <q-btn @click="envoi" :loading="loading" color="primary" style="width:100%" :disabled="enableValidation">Validez
        </q-btn>
      </div>
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
  <q-dialog v-model="messageSms" persistent>
    <q-card style="min-width: 350px">
      <q-card-section>
        <div class="text-h6">Saisissez le numéro reçu par {{ typeOfReset }}</div>
      </q-card-section>

      <q-card-section  >
        <div class="row">
          <q-input  class="input self-center" maxlength="5" mask="#####" style="width:100%;font-size: 30px" rounded outlined v-model="code" autofocus/>
        </div>
      </q-card-section>
      <q-card-actions align="right" class="text-primary">
        <q-btn @click="doReloadPage" flat label="Abandonner" v-close-popup/>
        <q-btn flat label="Valider" v-close-popup/>
      </q-card-actions>
    </q-card>
  </q-dialog>
</template>

<script setup>
import {ref} from 'vue'
import {computed,onMounted} from 'vue';


const messageType = ref('bg-secondary')
const messageText = ref('')
const messageSms = ref(false)
const messageAction = ref('reloadPage')
const message = ref(false)
const loading = ref(false)
const action = ref('change')
const username = ref('')
const oldpassword = ref('')
const newpassword = ref('')
const actionReset = ref('mail')
const typeOfReset = ref('SMS')
const code = ref('')
const enableByMail = ref(true)
const enableBySms = ref(true)
const passwordPolicies=ref({
  bannedTime:3600,
  checkPwned:true,
  goodComplexity:60,
  hasLowerCase:1,
  hasNumbers:1,
  hasSpecialChars:1,
  hasUpperCase:1,
  len:10,
  maxRetry:10,
  minComplexity:20,
  resetBySms:false,
  redirectUrl: ''
})
onMounted(async ()=>{
  const requestOptions = { method:'GET'}
  let rep= await fetch('/management/passwd/getpolicies')
  if (rep.status === 200){
    let response =await rep.json();
    passwordPolicies.value=response.data
    enableBySms.value=passwordPolicies.value.resetBySms
    debugger
  }else{
    messageAction.value = 'reloadPage'
    messageText.value = 'Une erreur c est produite : ' + rep.status
    messageType.value = 'bg-negative'
    message.value = true
  }
  }
)
const enableValidation = computed(() => {
  if (action.value === 'change') {
    if (username.value !== '' &&
      oldpassword.value !== '' &&
      newpassword.value !== '') {
      return false
    }
  }
  if (action.value === 'reset' && actionReset.value === 'mail') {
    if (username.value !== '') {
      return false
    }
  }
  if (action.value === 'reset' && actionReset.value === 'sms') {
    if (username.value !== '') {
      return false
    }
  }
  return true
})
const optionsReset = () => {
  const options = []
  if (enableByMail.value === true) {
    options.push({label: 'Par mail', value: 'mail'})
  }
  if (enableBySms.value === true) {
    options.push({label: 'Par sms', value: 'sms'})
  }
  return options
}

function resetData() {
  username.value = ''
  oldpassword.value = ''
  newpassword.value = ''

}

function envoi() {
  if (action.value === 'reset') {
    if (actionReset.value === 'mail') {
      typeOfReset.value = 'MAIL'
      messageSms.value = true
      resetData()
    }
    if (actionReset.value === 'sms') {
      typeOfReset.value = 'SMS'
      messageSms.value = true
      resetData()
    }
  }
  if (action.value === 'change') {
    const requestOptions = {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({uid: username.value, oldPassword: oldpassword.value, newPassword: newpassword.value})
    }
    loading.value = true
    enableValidation.value = false
    fetch('/management/passwd/change', requestOptions)
      .then(async response => {
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
        console.error('There was an error!', error);
      })

  }
}

function actionResetRenit() {
  username.value = ''
}

function doActionMessage() {
  if (messageAction.value === 'reloadPage') {
    window.location.reload()
  }
  if (messageAction.value === 'redirect') {
      window.location.replace(passwordPolicies.value.redirectUrl )
  }
}

function doReloadPage() {
  window.location.reload()
}

</script>

<style scoped>

</style>
