import { OrbitControls, PerspectiveCamera } from '@react-three/drei';
import { Canvas, useFrame, useThree } from '@react-three/fiber';
import React, { useEffect, useLayoutEffect, useMemo, useRef } from 'react';
import * as THREE from 'three';
import {
  ANT_FOOT_CLEARANCE,
  CELL_SIZE,
  NEST_IX,
  NEST_IZ,
  TERRAIN_VISUAL_SCALE,
} from '../simulation/constants';
import type { World } from '../simulation/world';
import {
  buildTerrainMeshGeometry,
  gridToWorldXZ,
  surfaceWorldY,
  updateTerrainMeshGeometry,
} from './terrainMesh';

export type ViewMode = 'surface' | 'underground';

const MAX_TUNNEL_INSTANCES = 900;
const MAX_GRAIN_INSTANCES = 4000;

function CameraPreset({ viewMode }: { viewMode: ViewMode }) {
  const { camera } = useThree();

  useEffect(() => {
    if (viewMode === 'surface') {
      camera.position.set(0, 62, 78);
    } else {
      camera.position.set(36, -18, 36);
    }
    camera.updateProjectionMatrix();
  }, [viewMode, camera]);

  return null;
}

export type SimStats = {
  tick: number;
  foodDelivered: number;
  antsForaging: number;
  looseGrains: number;
};

function SimulationContent({
  world,
  viewMode,
  onStats,
}: {
  world: World;
  viewMode: ViewMode;
  onStats: (s: SimStats) => void;
}) {
  const antMesh = useRef<THREE.InstancedMesh>(null);
  const tunnelMesh = useRef<THREE.InstancedMesh>(null);
  const grainMesh = useRef<THREE.InstancedMesh>(null);
  const terrainMesh = useRef<THREE.Mesh>(null);
  const dummy = useMemo(() => new THREE.Object3D(), []);
  const uiAcc = useRef(0);
  const lastTerrainV = useRef(-1);

  const antGeo = useMemo(
    () => new THREE.CapsuleGeometry(CELL_SIZE * 0.2, CELL_SIZE * 0.45, 5, 8),
    []
  );
  const antMat = useMemo(
    () =>
      new THREE.MeshStandardMaterial({
        color: '#241610',
        roughness: 0.65,
        metalness: 0.08,
      }),
    []
  );

  const tunnelGeo = useMemo(
    () => new THREE.BoxGeometry(CELL_SIZE * 0.88, CELL_SIZE * 0.7, CELL_SIZE * 0.88),
    []
  );
  const tunnelMat = useMemo(
    () =>
      new THREE.MeshStandardMaterial({
        color: '#4a3d32',
        roughness: 0.92,
        metalness: 0.04,
      }),
    []
  );

  const grainGeo = useMemo(
    () => new THREE.SphereGeometry(CELL_SIZE * 0.14, 6, 5),
    []
  );
  const grainMat = useMemo(
    () =>
      new THREE.MeshStandardMaterial({
        color: '#c9b896',
        roughness: 0.98,
        metalness: 0,
      }),
    []
  );

  const terrainGeo = useMemo(
    () => buildTerrainMeshGeometry(world.terrainHeight),
    [world]
  );

  const sandMaterial = useMemo(
    () =>
      new THREE.MeshStandardMaterial({
        color: '#d2c4a2',
        roughness: 0.98,
        metalness: 0,
        flatShading: true,
        transparent: true,
        opacity: 1,
        depthWrite: true,
      }),
    []
  );

  const antCount = world.ants.length;

  useLayoutEffect(() => {
    const tm = tunnelMesh.current;
    if (tm) tm.count = 0;
    const gm = grainMesh.current;
    if (gm) gm.count = 0;
  }, []);

  useFrame((_, delta) => {
    world.step(delta);

    if (world.terrainVersion !== lastTerrainV.current) {
      lastTerrainV.current = world.terrainVersion;
      const geo = terrainMesh.current?.geometry;
      if (geo) updateTerrainMeshGeometry(geo, world.terrainHeight);
    }

    uiAcc.current += delta;
    if (uiAcc.current > 0.22) {
      uiAcc.current = 0;
      const foraging = world.ants.filter((a) => a.role === 'forage').length;
      onStats({
        tick: world.tick,
        foodDelivered: world.foodDelivered,
        antsForaging: foraging,
        looseGrains: world.grains.length,
      });
    }

    const am = antMesh.current;
    if (am) {
      let i = 0;
      for (const ant of world.ants) {
        const y = surfaceWorldY(world, ant.x, ant.z);
        const p = gridToWorldXZ(ant.x, ant.z, y);
        dummy.position.copy(p);
        dummy.rotation.set(0, -ant.theta + Math.PI / 2, 0);
        dummy.scale.set(1, 1, 1);
        dummy.updateMatrix();
        am.setMatrixAt(i, dummy.matrix);
        i += 1;
      }
      am.instanceMatrix.needsUpdate = true;
    }

    const tm = tunnelMesh.current;
    if (tm) {
      const keys = [...world.tunnels];
      const n = Math.min(keys.length, MAX_TUNNEL_INSTANCES);
      tm.count = n;
      for (let i = 0; i < n; i++) {
        const [ix, iz, depth] = keys[i].split(',').map(Number);
        const surf = world.heightAt(ix, iz) * TERRAIN_VISUAL_SCALE;
        const py = surf - depth * CELL_SIZE * 0.7 - CELL_SIZE * 0.12;
        const p = gridToWorldXZ(ix, iz, py);
        dummy.position.copy(p);
        dummy.rotation.set(0, 0, 0);
        dummy.scale.set(1, 1, 1);
        dummy.updateMatrix();
        tm.setMatrixAt(i, dummy.matrix);
      }
      tm.instanceMatrix.needsUpdate = true;
    }

    const gm = grainMesh.current;
    if (gm) {
      const grains = world.grains;
      const count = Math.min(grains.length, MAX_GRAIN_INSTANCES);
      gm.count = count;
      for (let i = 0; i < count; i++) {
        const g = grains[i];
        const y = g.y * TERRAIN_VISUAL_SCALE + ANT_FOOT_CLEARANCE * 0.35;
        const p = gridToWorldXZ(g.x, g.z, y);
        dummy.position.copy(p);
        const s = 0.85 + (i % 5) * 0.06;
        dummy.scale.set(s, s, s);
        dummy.rotation.set(0, (i * 0.7) % (Math.PI * 2), 0);
        dummy.updateMatrix();
        gm.setMatrixAt(i, dummy.matrix);
      }
      gm.instanceMatrix.needsUpdate = true;
    }
  });

  useEffect(() => {
    sandMaterial.opacity = viewMode === 'surface' ? 1 : 0.22;
    sandMaterial.depthWrite = viewMode === 'surface';
  }, [viewMode, sandMaterial]);

  const nestGroundY = world.heightAt(NEST_IX, NEST_IZ) * TERRAIN_VISUAL_SCALE;
  const nestCenterY = nestGroundY + CELL_SIZE * 0.23;
  const nestPos = gridToWorldXZ(NEST_IX, NEST_IZ, nestCenterY);

  return (
    <>
      <CameraPreset viewMode={viewMode} />
      <PerspectiveCamera makeDefault fov={48} near={0.1} far={1400} />
      <color attach="background" args={[viewMode === 'surface' ? '#9ec8e8' : '#1a2433']} />
      <ambientLight intensity={viewMode === 'surface' ? 0.52 : 0.36} />
      <directionalLight
        castShadow
        position={[90, 120, 70]}
        intensity={viewMode === 'surface' ? 1.0 : 0.48}
        shadow-mapSize-width={1024}
        shadow-mapSize-height={1024}
        shadow-camera-far={400}
        shadow-camera-left={-120}
        shadow-camera-right={120}
        shadow-camera-top={120}
        shadow-camera-bottom={-120}
      />
      <hemisphereLight args={['#cfe8ff', '#c4b89a', 0.42]} />

      <mesh ref={terrainMesh} geometry={terrainGeo} material={sandMaterial} receiveShadow castShadow />

      {world.foodSources.map((f, idx) => {
        const groundY = world.heightAt(f.ix, f.iz) * TERRAIN_VISUAL_SCALE;
        const p = gridToWorldXZ(f.ix, f.iz, groundY + CELL_SIZE * 0.11);
        return (
          <mesh key={idx} position={p} castShadow>
            <cylinderGeometry args={[f.radius * CELL_SIZE * 0.82, f.radius * CELL_SIZE * 0.82, CELL_SIZE * 0.22, 20]} />
            <meshStandardMaterial color="#c4a35a" roughness={0.88} emissive="#2a1f08" emissiveIntensity={0.12} />
          </mesh>
        );
      })}

      <mesh position={nestPos} castShadow receiveShadow>
        <cylinderGeometry args={[CELL_SIZE * 4.8, CELL_SIZE * 5.2, CELL_SIZE * 0.45, 28]} />
        <meshStandardMaterial color="#4a3d2e" roughness={0.96} />
      </mesh>

      <instancedMesh
        ref={tunnelMesh}
        args={[tunnelGeo, tunnelMat, MAX_TUNNEL_INSTANCES]}
        castShadow
        receiveShadow
        frustumCulled={false}
      />

      <instancedMesh
        ref={grainMesh}
        args={[grainGeo, grainMat, MAX_GRAIN_INSTANCES]}
        castShadow
        receiveShadow
        frustumCulled={false}
      />

      <instancedMesh ref={antMesh} args={[antGeo, antMat, antCount]} castShadow frustumCulled={false} />

      <OrbitControls
        key={viewMode}
        enablePan
        enableZoom
        minDistance={10}
        maxDistance={260}
        maxPolarAngle={Math.PI * 0.95}
      />
    </>
  );
}

export function AnthillScene({
  world,
  viewMode,
  onStats,
}: {
  world: World;
  viewMode: ViewMode;
  onStats: (s: SimStats) => void;
}) {
  return (
    <Canvas
      shadows
      dpr={[1, 2]}
      style={{ flex: 1, width: '100%', minHeight: 0, height: '100%', alignSelf: 'stretch' }}
      gl={{ antialias: true, alpha: false }}
    >
      <SimulationContent world={world} viewMode={viewMode} onStats={onStats} />
    </Canvas>
  );
}
