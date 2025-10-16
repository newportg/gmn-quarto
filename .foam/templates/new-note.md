---
foam_template:
  filepath: "/content/Journal/posts/${FOAM_DATE_YEAR}-${FOAM_DATE_MONTH}-${FOAM_DATE_DATE}/index.qmd"
  description: ${FOAM_TITLE}
layout: post
title: ${FOAM_TITLE}
categories: [${FOAM_TITLE}]
author: "Gary Newport"
date: "${FOAM_DATE_YEAR}-${FOAM_DATE_MONTH}-${FOAM_DATE_DATE}"

output:
  html_document:
    toc: true
---



