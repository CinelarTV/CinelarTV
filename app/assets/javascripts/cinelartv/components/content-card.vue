<template>
  <li class="content-item" tabindex="0">
    <a :href="`/contents/${data.id}`" class="recyclerview-card-article aspect-video">
      <section class="recyclerview-card-article__section">
        <div class="recyclerview-card-article__element">
          <RouterLink :to="`/contents/${data.id}`" tabindex="-1">
            <div class="recyclerview-card-article__image aspect-video">
              <img :src="data.banner" alt="Cover Image" />
            </div>
            <div class="recyclerview-card-article__overlay"
              :class="data.duration && data.progress ? 'with-progress' : ''">
              <div class="recyclerview-card-article__title">
                {{ data.title }}
              </div>
              <div class="recyclerview-card-article__progress" v-if="data.progress && data.duration">
                <div class="recyclerview-card-article__progress__bar">
                  <div class="recyclerview-card-article__progress__bar__progress"
                    :style="`width: ${(data.progress / data.duration) * 100}%`">
                  </div>
                </div>
              </div>
            </div>
          </RouterLink>
        </div>
      </section>
      <img :src="data.banner" class="blurred-shadow" :alt="data.title" />
      <div class="expanded-info" v-if="isHovering">
        <div class="expanded-info__title">
          {{ data.title }}
        </div>
        <div class="expanded-info__description">
          {{ data.description }}
        </div>
      </div>
    </a>
  </li>
</template>

<script setup>
import { defineProps, ref } from 'vue'

const props = defineProps({
  data: {
    type: Object,
    required: true
  }
})

const isHovering = ref(false)

</script>
