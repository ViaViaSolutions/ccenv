"use client";

import { useEffect, useState } from "react";

export function CustomCursor() {
  const [position, setPosition] = useState({ x: 0, y: 0 });
  const [isHovered, setIsHovered] = useState(false);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    // Only enable for pointer: fine (devices with mouse/trackpad)
    const mediaQuery = window.matchMedia("(any-pointer: fine)");
    if (!mediaQuery.matches) return;

    setIsVisible(true);

    const handleMouseMove = (e: MouseEvent) => {
      setPosition({ x: e.clientX, y: e.clientY });
    };

    const handleMouseOver = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      if (
        target.tagName === "A" ||
        target.tagName === "BUTTON" ||
        target.closest("a") ||
        target.closest("button") ||
        target.classList.contains("cursor-pointer")
      ) {
        setIsHovered(true);
      } else {
        setIsHovered(false);
      }
    };

    const handleMouseLeave = () => {
      setIsVisible(false);
    };

    const handleMouseEnter = () => {
      setIsVisible(true);
    };

    window.addEventListener("mousemove", handleMouseMove);
    window.addEventListener("mouseover", handleMouseOver);
    document.addEventListener("mouseleave", handleMouseLeave);
    document.addEventListener("mouseenter", handleMouseEnter);

    return () => {
      window.removeEventListener("mousemove", handleMouseMove);
      window.removeEventListener("mouseover", handleMouseOver);
      document.removeEventListener("mouseleave", handleMouseLeave);
      document.removeEventListener("mouseenter", handleMouseEnter);
    };
  }, []);

  if (!isVisible) return null;

  return (
    <div
      className="pointer-events-none fixed top-0 left-0 z-50 -translate-x-1/2 -translate-y-1/2 transition-transform duration-100 ease-out"
      style={{
        transform: `translate3d(${position.x}px, ${position.y}px, 0) scale(${isHovered ? 1.4 : 1})`,
      }}
    >
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="28" height="28" shapeRendering="crispEdges">
        <rect x="2" y="3" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="3" y="3" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="4" y="3" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="5" y="3" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="6" y="3" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="7" y="3" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="8" y="3" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="9" y="3" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="10" y="3" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="11" y="3" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="12" y="3" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="13" y="3" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="2" y="4" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="3" y="4" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="4" y="4" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="5" y="4" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="6" y="4" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="7" y="4" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="8" y="4" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="9" y="4" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="10" y="4" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="11" y="4" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="12" y="4" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="13" y="4" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="2" y="5" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="3" y="5" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="4" y="5" width="1" height="1" fill="var(--spot)" fillOpacity="0.502" />
        <rect x="5" y="5" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="6" y="5" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="7" y="5" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="8" y="5" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="9" y="5" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="10" y="5" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="11" y="5" width="1" height="1" fill="var(--spot)" fillOpacity="0.502" />
        <rect x="12" y="5" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="13" y="5" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="2" y="6" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="3" y="6" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="5" y="6" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="6" y="6" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="7" y="6" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="8" y="6" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="9" y="6" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="10" y="6" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="12" y="6" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="13" y="6" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="0" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="1" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="2" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="3" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="4" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="5" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="6" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="7" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="8" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="9" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="10" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="11" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="12" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="13" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="14" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="15" y="7" width="1" height="1" fill="var(--spot)" fillOpacity="0.749" />
        <rect x="0" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="1" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="2" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="3" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="4" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="5" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="6" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="7" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="8" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="9" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="10" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="11" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="12" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="13" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="14" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="15" y="8" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="0" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="0.251" />
        <rect x="1" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="0.251" />
        <rect x="2" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="3" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="4" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="5" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="6" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="7" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="8" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="9" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="10" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="11" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="12" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="13" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="14" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="0.251" />
        <rect x="15" y="9" width="1" height="1" fill="var(--spot)" fillOpacity="0.251" />
        <rect x="2" y="10" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="3" y="10" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="4" y="10" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="5" y="10" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="6" y="10" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="7" y="10" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="8" y="10" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="9" y="10" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="10" y="10" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="11" y="10" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="12" y="10" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="13" y="10" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="2" y="11" width="1" height="1" fill="var(--spot)" fillOpacity="0.502" />
        <rect x="3" y="11" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="4" y="11" width="1" height="1" fill="var(--spot)" fillOpacity="0.502" />
        <rect x="5" y="11" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="6" y="11" width="1" height="1" fill="var(--spot)" fillOpacity="0.502" />
        <rect x="7" y="11" width="1" height="1" fill="var(--spot)" fillOpacity="0.502" />
        <rect x="8" y="11" width="1" height="1" fill="var(--spot)" fillOpacity="0.502" />
        <rect x="9" y="11" width="1" height="1" fill="var(--spot)" fillOpacity="0.502" />
        <rect x="10" y="11" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="11" y="11" width="1" height="1" fill="var(--spot)" fillOpacity="0.502" />
        <rect x="12" y="11" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="13" y="11" width="1" height="1" fill="var(--spot)" fillOpacity="0.502" />
        <rect x="3" y="12" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="5" y="12" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="10" y="12" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="12" y="12" width="1" height="1" fill="var(--spot)" fillOpacity="1.0" />
        <rect x="3" y="13" width="1" height="1" fill="var(--spot)" fillOpacity="0.251" />
        <rect x="5" y="13" width="1" height="1" fill="var(--spot)" fillOpacity="0.251" />
        <rect x="10" y="13" width="1" height="1" fill="var(--spot)" fillOpacity="0.251" />
        <rect x="12" y="13" width="1" height="1" fill="var(--spot)" fillOpacity="0.251" />
      </svg>
    </div>
  );
}
