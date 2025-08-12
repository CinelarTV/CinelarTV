import { defineComponent } from "vue"

/* A very simple spinner component */
export default defineComponent({
  name: 'CSpinner',
  props: {
    small: {
      type: Boolean,
      default: false
    }
  },
  setup(props) {
    return () => (
      <div class={`spinner ${props.small ? 'small' : ''}`} />
    )
  }
})
