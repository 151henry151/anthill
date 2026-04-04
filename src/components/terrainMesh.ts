import * as THREE from 'three';
import { ANT_FOOT_CLEARANCE, CELL_SIZE, GRID_SIZE, TERRAIN_VISUAL_SCALE } from '../simulation/constants';
import { sampleHeightBilinear } from '../simulation/terrain';

export const TERRAIN_SEGMENTS = 100;

const halfExtent = (GRID_SIZE * CELL_SIZE) / 2;

export function buildTerrainMeshGeometry(heights: Float32Array): THREE.BufferGeometry {
  const seg = TERRAIN_SEGMENTS;
  const verts = (seg + 1) * (seg + 1);
  const positions = new Float32Array(verts * 3);
  const indices: number[] = [];

  let vi = 0;
  for (let j = 0; j <= seg; j++) {
    for (let i = 0; i <= seg; i++) {
      const gx = (i / seg) * (GRID_SIZE - 1);
      const gz = (j / seg) * (GRID_SIZE - 1);
      const y = sampleHeightBilinear(heights, gx, gz) * TERRAIN_VISUAL_SCALE;
      positions[vi++] = gx * CELL_SIZE - halfExtent;
      positions[vi++] = y;
      positions[vi++] = gz * CELL_SIZE - halfExtent;
    }
  }

  for (let j = 0; j < seg; j++) {
    for (let i = 0; i < seg; i++) {
      const a = i + j * (seg + 1);
      const b = a + 1;
      const c = a + (seg + 1);
      const d = c + 1;
      indices.push(a, c, b, b, c, d);
    }
  }

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geo.setIndex(indices);
  geo.computeVertexNormals();
  return geo;
}

export function updateTerrainMeshGeometry(geo: THREE.BufferGeometry, heights: Float32Array): void {
  const seg = TERRAIN_SEGMENTS;
  const pos = geo.attributes.position as THREE.BufferAttribute;
  const arr = pos.array as Float32Array;
  let vi = 0;
  for (let j = 0; j <= seg; j++) {
    for (let i = 0; i <= seg; i++) {
      const gx = (i / seg) * (GRID_SIZE - 1);
      const gz = (j / seg) * (GRID_SIZE - 1);
      const y = sampleHeightBilinear(heights, gx, gz) * TERRAIN_VISUAL_SCALE;
      arr[vi++] = gx * CELL_SIZE - halfExtent;
      arr[vi++] = y;
      arr[vi++] = gz * CELL_SIZE - halfExtent;
    }
  }
  pos.needsUpdate = true;
  geo.computeVertexNormals();
}

export function gridToWorldXZ(x: number, z: number, y: number): THREE.Vector3 {
  return new THREE.Vector3(x * CELL_SIZE - halfExtent, y, z * CELL_SIZE - halfExtent);
}

export function surfaceWorldY(world: { heightAt: (x: number, z: number) => number }, x: number, z: number): number {
  return world.heightAt(x, z) * TERRAIN_VISUAL_SCALE + ANT_FOOT_CLEARANCE;
}
