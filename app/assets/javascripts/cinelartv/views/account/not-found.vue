<template>
    <div class="account-route page-not-found">
        <div class="flex flex-col items-center">
            <c-icon icon="alert-circle" :size="64" class="text-red-500" />
            <h1 class="text-2xl font-medium mt-4">Página no encontrada</h1>
            <p class="text-gray-500 mt-2">La página que estás buscando no existe.</p>
            <router-link to="/" class="button mt-4">Volver al inicio</router-link>
        </div>
    </div>
</template>