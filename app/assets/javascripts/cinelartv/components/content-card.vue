<template>
    <li class="content-item">
      <article class="recyclerview-card-article">
        <section class="recyclerview-card-article__section">
          <div class="recyclerview-card-article__element">
            <RouterLink :to="`/contents/${data.id}`">
              <div class="recyclerview-card-article__image" style="aspect-ratio:16/9">
                <img :src="data.banner" alt="Cover Image" />
              </div>
              <div class="recyclerview-card-article__overlay" :class="data.duration && data.progress ? 'with-progress' : ''">
                <div class="recyclerview-card-article__title">
                  {{ data.title }}
                </div>
                <div class="recyclerview-card-article__progress" v-if="data.progress && data.duration">
                  <div class="recyclerview-card-article__progress__bar">
                    <div class="recyclerview-card-article__progress__bar__progress" :style="`width: ${(data.progress / data.duration) * 100}%`">
                    </div>
                  </div>
                </div>
              </div>
            </RouterLink>
          </div>
        </section>
      </article>
    </li>
  </template>
  
  <script>
  export default {
    props: {
      data: Object
    },
  };
  </script>