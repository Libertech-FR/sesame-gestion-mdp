<template>

  <q-card class="shadow-24 row q-py-auto" style="max-width: 800px;">
    <q-toolbar class="bg-primary text-white">
      <q-toolbar-title>Gestion de votre accès</q-toolbar-title>
    </q-toolbar>
    <q-card-section class="col-lg-4 flex items-center mobile-hide">
      <q-img src="/img/logo.png" style="max-width: 100%;width:500px;"/>
    </q-card-section>
    <q-card-section class="col-lg-8  column">
      <div class="q-pa-md row-md" v-show="action !=='menu' && withMenu ===false">
        <q-btn-toggle
            v-model="action"
            @click="resetData()"
            spread
            push
            glossy
            no-caps
            rounded
            unelevated
            toggle-color="primary"
            color="blue-grey-1"
            text-color="primary"
            :options="[
          {label: 'Changer votre mot de passe', value: 'change'},
          {label: 'Reinitialiser votre mot de passe', value: 'reset'}
        ]"
        />
      </div>
        <div class="q-pa-md row-md " v-show="action ==='menu'">

          <q-btn @click='onmenuChange()' class="q-py-sm fit glossy"  color="primary">Changer mon mot de passe</q-btn>
          <q-separator class="q-mt-sm q-mb-sm" />
          <q-btn @click='onmenuReset()' class="q-py-sm fit glossy"  color="primary">J'ai oublié mon mot de passe</q-btn>
      </div>







      <div v-show="action == 'change'" class="row-md">
        <q-input v-model="username" :label="userLabel" type="text"></q-input>
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
              push
              glossy
              no-caps
              rounded
              unelevated
              toggle-color="warning"
              color="white"
              text-color="primary"
              :options="optionsReset()"
          />
        </div>
        <q-input v-model="username" :label="userLabel" type="text"></q-input>
      </div>
      <div v-show="action !== '' && action !== 'menu'" class="row-md" style="margin-top: 30px;">
        <q-btn v-show="withMenu===true" @click="action='menu'"  color="negative" :style="getButtonsWidth()" >Abandonner</q-btn>
        <q-btn @click="envoi" :loading="loading" color="primary" :style="getButtonsWidth()" :disabled="enableValidation">Validez
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
        <q-card-section>
          <div class="text-h5">Saisissez le code reçu par {{ typeOfReset }}</div>
          <q-input class="input self-center" maxlength="6" mask="######" style="width:100%;font-size: 30px" rounded
                   outlined v-model="code" autofocus/>
        </q-card-section>
        <q-card-section>
          <div class="text-h5">Définisez votre nouveau mot de passe</div>
        </q-card-section>
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

      </q-card-section>
      <q-card-actions align="right" class="text-primary"  >
        <q-btn @click="doReloadPage" flat label="Abandonner" v-close-popup/>
        <q-btn @click="actionSendReset" flat label="Valider" v-close-popup :disabled="enableValidationCode"/>
      </q-card-actions>
    </q-card>
  </q-dialog>
</template>

<script setup>
import {ref} from 'vue'
import {computed, onMounted} from 'vue';
const config = useAppConfig()
const userLabel=ref(config.userLabel)
const messageType = ref('bg-secondary')
const messageText = ref('')
const messageSms = ref(false)
const messageAction = ref('reloadPage')
const message = ref(false)
const loading = ref(false)
const action = ref(config.action)
const withMenu=ref(false)
const username = ref('')
const oldpassword = ref('')
const newpassword = ref('')
const actionReset = ref('mail')
const typeOfReset = ref('SMS')
const code = ref('')
const resetToken = ref('')
const enableByMail = ref(true)
const enableBySms = ref(true)
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
        enableBySms.value = passwordPolicies.value.resetBySms
      } else {
        messageAction.value = 'reloadPage'
        messageText.value = 'Une erreur c est produite : ' + rep.status
        messageType.value = 'bg-negative'
        message.value = true
      }
    }
)
const enableValidationCode = computed(() => {
  if (code.value !== '' && newpassword.value !== '') {
    return false
  }
  return true
})
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
function getButtonsWidth(){
  if (withMenu.value === true){
    return "width: 50%;"
  }else{
    return "width: 100%;"
  }
}
function onmenuChange(){
  action.value='change'
  withMenu.value=true
}
function onmenuReset(){
  action.value='reset'
  withMenu.value=true
}
function envoi() {
  if (action.value === 'reset') {
    if (actionReset.value === 'mail') {
      actionInitReset(0)
    }
    if (actionReset.value === 'sms') {
      typeOfReset.value = 'SMS'
      messageSms.value = true
      actionInitReset(1)
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
          if (response.status === 200) {
            messageAction.value = 'redirect'
            messageText.value = 'Votre mot de passe a été changé. Vous pouvez vous connecter'
            messageType.value = 'bg-secondary'
            message.value = true
          } else if (response.status === 400) {
            messageAction.value = 'reloadPage'
            messageText.value = 'Erreur d\'authentification. Veuillez réessayer.'
            messageType.value = 'bg-negative'
            message.value = true
          } else {
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

function actionInitReset(resetType) {
  //demande de reinit
  const requestOptions = {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({uid: username.value, type: resetType})
  }
  if (resetType === 0) {
    typeOfReset.value = 'mail'
  } else {
    typeOfReset.value = 'SMS'
  }

  loading.value = true
  enableValidation.value = false
  fetch('/management/passwd/initreset', requestOptions)
      .then(async response => {
        const isJson = response.headers.get('content-type')?.includes('application/json');
        const data = isJson && await response.json();
        console.log('status :' + data.status)
        // check for error response
        if (response.status === 200) {
          resetToken.value = data.token
          messageSms.value = true
        } else {
          messageAction.value = 'reloadPage'
          messageText.value = 'Une erreur c est produite : ' + error
          messageType.value = 'bg-negative'
          message.value = true
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

function actionSendReset() {
  const requestOptions = {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
      token: resetToken.value,
      code: parseInt(code.value),
      newpassword: newpassword.value
    })
  }
  fetch('/management/passwd/resetbycode', requestOptions)
      .then(async response => {
        const isJson = response.headers.get('content-type')?.includes('application/json');
        const data = isJson && await response.json();
        console.log('status :' + data.status)
        // check for error response
        if (response.status === 200) {
          messageAction.value = 'redirect'
          messageText.value = 'Votre mot de passe a été reinitialisé'
          messageType.value = 'bg-positive'
          message.value = true
        } else {
          messageAction.value = 'reloadPage'
          messageText.value = 'Une erreur c\'est produite : ' + error
          messageType.value = 'bg-negative'
          message.value = true
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

function doActionMessage() {
  if (messageAction.value === 'reloadPage') {
    window.location.reload()
  }
  if (messageAction.value === 'redirect') {
    window.location.replace(passwordPolicies.value.redirectUrl)
  }
}

function doReloadPage() {
  window.location.reload()
}

</script>

<style scoped>

</style>
