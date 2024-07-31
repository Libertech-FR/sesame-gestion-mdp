<template>
  <q-page class="window-height window-width row justify-center items-center bg-image">
    <LoginMenu></LoginMenu>
  </q-page>
</template>
<script>
export default {
  name: "index.vue"
}
</script>

<style scoped>
.bg-image {
  background-image: url(/img/background.png);
  background-repeat: no-repeat;
  background-size: 100%;
}

</style>