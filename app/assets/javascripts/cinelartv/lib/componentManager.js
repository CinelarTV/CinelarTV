// componentManager.js

import { compile } from "vue-template-compiler";
import { ref } from 'vue';

const plugins = ref({});
const componentInstances = {};

const addPluginComponent = (template, outlet) => {
  if (!plugins.value[outlet]) {
    plugins.value[outlet] = [];
  }

  plugins.value[outlet].push({ template });

  return plugins.value[outlet];
};

const addCompiledComponent = (template, outlet) => {
  const compiledComponent = compile(template);

  if (!componentInstances[outlet]) {
    componentInstances[outlet] = [];
  }

  componentInstances[outlet].push(compiledComponent);

  addPluginComponent(template, outlet);
  return compiledComponent;
};

export { addPluginComponent, addCompiledComponent, plugins };
