import { OrbitControls, PerspectiveCamera } from '@react-three/drei';
import { Canvas, useFrame, useThree } from '@react-three/fiber';
import React, { useEffect, useLayoutEffect, useMemo, useRef } from 'react';
import * as THREE from 'three';
import { CELL_SIZE, GRID_SIZE, NEST_IX, NEST_IZ } from '../simulation/constants';
import type { World } from '../simulation/world';

export type ViewMode = 'surface' | 'underground';

const MAX_TUNNEL_INSTANCES = 600;

function gridToWorld(x: number, z: number, y: number): THREE.Vector3 {
  const half = (GRID_SIZE * CELL_SIZE) / 2;
  return new THREE.Vector3(x * CELL_SIZE - half, y, z * CELL_SIZE - half);
}

function CameraPreset({ viewMode }: { viewMode: ViewMode }) {
  const { camera } = useThree();

  useEffect(() => {
    if (viewMode === 'surface') {
      camera.position.set(0, 48, 52);
    } else {
      camera.position.set(22, -12, 22);
    }
    camera.updateProjectionMatrix();
  }, [viewMode, camera]);

  return null;
}

function SimulationContent({
  world,
  viewMode,
  onStats,
}: {
  world: World;
  viewMode: ViewMode;
  onStats: (s: { tick: number; foodDelivered: number; antsForaging: number }) => void;
}) {
  const antMesh = useRef<THREE.InstancedMesh>(null);
  const tunnelMesh = useRef<THREE.InstancedMesh>(null);
  const dummy = useMemo(() => new THREE.Object3D(), []);
  const uiAcc = useRef(0);

  const antGeo = useMemo(
    () => new THREE.CapsuleGeometry(CELL_SIZE * 0.22, CELL_SIZE * 0.5, 6, 10),
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
    () => new THREE.BoxGeometry(CELL_SIZE * 0.92, CELL_SIZE * 0.75, CELL_SIZE * 0.92),
    []
  );
  const tunnelMat = useMemo(
    () =>
      new THREE.MeshStandardMaterial({
        color: '#5c4033',
        roughness: 0.9,
        metalness: 0.05,
      }),
    []
  );

  const antCount = world.ants.length;

  useLayoutEffect(() => {
    const tm = tunnelMesh.current;
    if (tm) {
      tm.count = 0;
    }
  }, []);

  useFrame((_, delta) => {
    world.step(delta);
    uiAcc.current += delta;
    if (uiAcc.current > 0.22) {
      uiAcc.current = 0;
      const foraging = world.ants.filter((a) => a.role === 'forage').length;
      onStats({
        tick: world.tick,
        foodDelivered: world.foodDelivered,
        antsForaging: foraging,
      });
    }

    const am = antMesh.current;
    if (am) {
      let i = 0;
      for (const ant of world.ants) {
        const p = gridToWorld(ant.x, ant.z, CELL_SIZE * 0.35);
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
        const p = gridToWorld(ix, iz, -depth * CELL_SIZE * 0.82 - CELL_SIZE * 0.2);
        dummy.position.copy(p);
        dummy.rotation.set(0, 0, 0);
        dummy.scale.set(1, 1, 1);
        dummy.updateMatrix();
        tm.setMatrixAt(i, dummy.matrix);
      }
      tm.instanceMatrix.needsUpdate = true;
    }
  });

  return (
    <>
      <CameraPreset viewMode={viewMode} />
      <PerspectiveCamera makeDefault fov={50} near={0.1} far={500} />
      <color attach="background" args={[viewMode === 'surface' ? '#87b8e8' : '#1a2433']} />
      <ambientLight intensity={viewMode === 'surface' ? 0.55 : 0.38} />
      <directionalLight
        castShadow
        position={[28, 44, 22]}
        intensity={viewMode === 'surface' ? 1.05 : 0.5}
        shadow-mapSize-width={1024}
        shadow-mapSize-height={1024}
      />
      <hemisphereLight args={['#cfe8ff', '#3a4a38', 0.35]} />

      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, 0, 0]} receiveShadow>
        <planeGeometry args={[GRID_SIZE * CELL_SIZE * 1.2, GRID_SIZE * CELL_SIZE * 1.2]} />
        <meshStandardMaterial
          color="#4a6741"
          roughness={0.92}
          metalness={0.02}
          transparent
          opacity={viewMode === 'surface' ? 1 : 0.15}
          depthWrite={viewMode === 'surface'}
        />
      </mesh>

      {world.foodSources.map((f, idx) => {
        const p = gridToWorld(f.ix, f.iz, CELL_SIZE * 0.15);
        return (
          <mesh key={idx} position={p} castShadow>
            <cylinderGeometry args={[f.radius * CELL_SIZE * 0.85, f.radius * CELL_SIZE * 0.85, CELL_SIZE * 0.25, 24]} />
            <meshStandardMaterial color="#c4a35a" roughness={0.8} emissive="#332208" emissiveIntensity={0.15} />
          </mesh>
        );
      })}

      <mesh position={gridToWorld(NEST_IX, NEST_IZ, CELL_SIZE * 0.18)} castShadow>
        <cylinderGeometry args={[CELL_SIZE * 4.2, CELL_SIZE * 4.8, CELL_SIZE * 0.4, 32]} />
        <meshStandardMaterial color="#3e2f2a" roughness={0.95} />
      </mesh>

      <instancedMesh
        ref={tunnelMesh}
        args={[tunnelGeo, tunnelMat, MAX_TUNNEL_INSTANCES]}
        castShadow
        receiveShadow
        frustumCulled={false}
      />

      <instancedMesh ref={antMesh} args={[antGeo, antMat, antCount]} castShadow frustumCulled={false} />

      <OrbitControls
        key={viewMode}
        enablePan
        enableZoom
        minDistance={6}
        maxDistance={130}
        maxPolarAngle={Math.PI * 0.95}
        target={[0, viewMode === 'surface' ? 0 : -4, 0]}
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
  onStats: (s: { tick: number; foodDelivered: number; antsForaging: number }) => void;
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
