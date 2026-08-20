'use client';

import { gsap } from 'gsap';
import { useGSAP } from '@gsap/react';
import { CustomEase } from 'gsap/CustomEase';
import { Flip } from 'gsap/Flip';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { ScrollToPlugin } from 'gsap/ScrollToPlugin';

if (typeof window !== 'undefined') {
  gsap.registerPlugin(useGSAP, Flip, ScrollTrigger, ScrollToPlugin, CustomEase);
}

export { gsap, useGSAP, CustomEase, Flip, ScrollTrigger, ScrollToPlugin };
