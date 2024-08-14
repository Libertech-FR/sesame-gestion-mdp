<template>
  <div>
    <div class="col-12">
    <q-input @update:model-value="checkPassword($event,'pass')" :label-color="pwdColor" v-model="newPassword"
             label="Nouveau mot de passe" :type="typePasswordProp">
      <template v-slot:append>
        <q-icon name="visibility" @click="togglePassword" style="cursor: pointer;"/>
      </template>

    </q-input>
    <q-input @update:model-value="checkPassword($event,'confirm')" v-model="confirmNewPassword" :label-color="confirmColor"
             label="Confirmation du nouveau mot de passe" :type="typeConfirmProp">
      <template v-slot:append>
        <q-icon name="visibility" @click="toggleConfirm" style="cursor: pointer;"/>
      </template>
    </q-input>
    </div>
    <div class="col-12">
      <p style="margin: 0px;">
        <q-icon :name="has_len" :color="has_len_color" size="xs" style="margin: 0px;"></q-icon>
        &nbsp;doit avoir au moins {{min}} caractères
      </p>
      <p v-show="minUpper > 0" style="margin: 0px;">
        <q-icon  :name="has_upper" :color="has_upper_color" size="xs" ></q-icon>
        &nbsp;doit comporter au moins {{minUpper}} majuscules
      </p>
      <p v-show="minLower > 0" style="margin: 0px;">
        <q-icon  :name="has_lower" :color="has_lower_color" size="xs" ></q-icon>
        &nbsp;doit comporter au moins {{minLower}} minuscules
      </p>
      <p  v-show="minNumber > 0" style="margin: 0px;">
        <q-icon  :name="has_number" :color="has_number_color" size="xs" ></q-icon>
        &nbsp;doit comporter au moins {{minNumber}} chiffre
      </p>
      <p v-show="minSpecial > 0" style="margin: 0px;">
        <q-icon  :name="has_special" :color="has_special_color" size="xs" ></q-icon>
        &nbsp;doit comporter au moins {{minNumber}} charactère special
      </p>
      <p v-show="minEntropy > 0" style="margin: 0px;">
        <q-icon  :name="has_complexity" :color="has_complexity_color" size="xs" ></q-icon>
        &nbsp; Complexité
        <br>
        <q-linear-progress :value="progress" :color="progress_color" class="q-mt-sm" size="10px" />
      </p>
      <p v-show="checkPwned">
        <q-icon  :name="isPwned" :color="isPwned_color" size="xs" ></q-icon>
        &nbsp; Exposition du mot de passe <a href="https://haveibeenpwned.com">haveiBeenPwned</a>
      </p>
    </div>
  </div>
</template>

<script setup>
import { useQuasar } from 'quasar'
import {ref} from 'vue'
import stringEntropy from 'fast-password-entropy'
import { pwnedPassword } from 'hibp';
const emit = defineEmits(['update:modelValue'])
const $q = useQuasar()
const newPassword = ref('')
const confirmNewPassword = ref('')
const pwdColor = ref('')
const confirmColor = ref('')
const has_len=ref('highlight_off')
const has_len_color=ref('red')
const has_upper=ref('highlight_off')
const has_upper_color=ref('red')
const has_lower=ref('highlight_off')
const has_lower_color=ref('red')
const has_number=ref('highlight_off')
const has_number_color=ref('red')
const has_special=ref('highlight_off')
const has_special_color=ref('red')
const has_complexity=ref('highlight_off')
const has_complexity_color=ref('red')
const isPwned=ref('sentiment_satisfied')
const isPwned_color=ref('grey')
const progress=ref(0)
const progress_color=ref('red')
const typePasswordProp=ref('password')
const typeConfirmProp=ref('password')
const props = defineProps({
  min: {
    type: Number,
    default:8},
  minUpper:{
    type: Number,
    default:1
  },
  minLower:{
    type: Number,
    default:1
  },
  minNumber:{
    type: Number,
    default:1
  },
  minSpecial:{
    type:Number,
    default:1
  },
  minEntropy:{
    type:Number,
    default:30
  },
  entropyBad:{
    type:Number,
    default:10
  },
  entropyGood:{
    type:Number,
    default:80
  },
  checkPwned:{
    type:Boolean,
    default:true
  }
})

async function checkPassword(ev, type) {
  let newP = newPassword.value
  let confirmP = confirmNewPassword.value
  if (type === 'pass') {
    newP = ev
  } else {
    confirmP = ev
  }
  if (checkPolicy(newP) === true) {
    if (newP === confirmP) {
      console.log('emit ' + newPassword.value)
      //avant d accepter on cherche dans l api de pwned
      try{
        if (props.checkPwned === true ){
          const numPwns = await pwnedPassword(newP);

          if (numPwns >0){
            iconIsPwnedOK(false)
            $q.notify({
              message: '<text-weight-medium>Ce mot de passe est déjà apparu lors d\'une violation de données. Vous ne pouvez pas l\'utiliser</text-weight-medium>',
            })
            emit('update:modelValue', '')
            return
          }else{
            iconIsPwnedOK(true)
          }
          console.log('pwn :' + numPwns)
        }
      }catch(err){

      }


      confirmColor.value='green'
      emit('update:modelValue', newPassword.value)
    }else{
      emit('update:modelValue', '')
      confirmColor.value='red'
    }
  }else{
    emit('update:modelValue', '')
  }
}

function checkPolicy(password) {
  has_len.value='highlight_off'
 let statut=true
  if (props.minSpecial >= 1){
    if (/[!@#\$%\^\&*\)\(+=._-]/.test(password) === false){
      pwdColor.value = 'red'
      iconSpecialOK(false)
      statut=false
    }else{
      iconSpecialOK(true)
    }
  }
  if (props.minNumber >= 1) {
    if (/\d/.test(password) === false) {
      pwdColor.value = 'red'
      iconNumberOK(false)
      statut = false
    } else {
      iconNumberOK(true)
    }
  }
  if (props.minLower >= 1) {
    if (/[a-z]/.test(password) === false) {
      pwdColor.value = 'red'
      iconLowerOK(false)
      statut = false
    } else {
      iconLowerOK(true)
    }
  }
  if (props.minUpper >= 1) {
    if (/[A-Z]/.test(password) === false) {
      pwdColor.value = 'red'
      iconUpperOK(false)
      statut = false
    } else {
      iconUpperOK(true)
    }
  }
  if (password.length < props.min) {
    console.log('trop court ' + props.min)
    iconLenOK(false)
    statut=false
  }else{
    iconLenOK(true)
  }
  console.log('password OK ')
  if (statut === true){
    pwdColor.value = 'green'
  }else {
    pwdColor.value = 'red'
  }
  //entropie
  if (complexity(password) === false){
    statut=false
    iconComplexityOK(false)
  }else{
    iconComplexityOK(true)
  }
  return statut
}
function iconComplexityOK(value){
  if (value === true){
    has_complexity.value='done'
    has_complexity_color.value='green'
  }else{
    has_complexity.value='highlight_off'
    has_complexity_color.value='red'
  }
}
function iconLenOK(value){
  if (value === true){
    has_len.value='done'
    has_len_color.value='green'
  }else{
    has_len.value='highlight_off'
    has_len_color.value='red'
  }
}
function iconUpperOK(value){
  if (value === true){
    has_upper.value='done'
    has_upper_color.value='green'
  }else{
    has_upper.value='highlight_off'
    has_upper_color.value='red'
  }
}
function iconLowerOK(value){
  if (value === true){
    has_lower.value='done'
    has_lower_color.value='green'
  }else{
    has_lower.value='highlight_off'
    has_lower_color.value='red'
  }
}
function iconNumberOK(value){
  if (value === true){
    has_number.value='done'
    has_number_color.value='green'
  }else{
    has_number.value='highlight_off'
    has_number_color.value='red'
  }
}
function iconSpecialOK(value){
  if (value === true){
    has_special.value='done'
    has_special_color.value='green'
  }else{
    has_special.value='highlight_off'
    has_special_color.value='red'
  }
}
function iconIsPwnedOK(value){
  if (value === true){
    isPwned.value='sentiment_satisfied'
    isPwned_color.value='green'
  }else{
    isPwned.value='sentiment_very_dissatisfied'
    isPwned_color.value='red'
  }
}
function complexity(password){
  console.log(stringEntropy(password))
  if (props.minEntropy > 0){
    let c = stringEntropy(password)
    progress.value = c / 100
    console.log('entropy' + c)
    if (c < props.entropyBad) {
      progress_color.value = 'red'
    } else if (c >= props.entropyBad && c < props.entropyGood) {
      progress_color.value = 'warning'
    } else {
      progress_color.value = 'green'
    }
    if (c >= props.minEntropy) {
      return true
    } else {
      return false
    }
  }
}
function togglePassword(){
  if (typePasswordProp.value === 'password'){
    typePasswordProp.value='text'
  }else{
    typePasswordProp.value='password'
  }
}
function toggleConfirm(){
  if (typeConfirmProp.value === 'password'){
    typeConfirmProp.value='text'
  }else{
    typeConfirmProp.value='password'
  }
}
</script>

<style scoped>

</style>
