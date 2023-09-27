<template>
    <div class="c-watchparty-chat">
        <div class="c-watchparty-chat__messages">
        <div class="c-watchparty-chat__messages__message" v-for="message in messages">
            <div class="c-watchparty-chat__messages__message__user">
            <img :src="message.user.avatar" />
            </div>
            <div class="c-watchparty-chat__messages__message__content">
            <div class="c-watchparty-chat__messages__message__content__user">
                {{ message.user.name }}
            </div>
            <div class="c-watchparty-chat__messages__message__content__text">
                {{ message.text }}
            </div>
            </div>
        </div>
        </div>
        <div class="c-watchparty-chat__input">
        <input type="text" v-model="message" @keyup.enter="sendMessage" />
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const message = ref('')

const messages = ref([])

const sendMessage = (message) => {
    messages.value = [...messages.value, { text: message, user: { name: 'Test', avatar: 'https://i.pravatar.cc/300' } }]
}
</script>