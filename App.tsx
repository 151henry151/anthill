import { StatusBar } from 'expo-status-bar';
import React, { useCallback, useRef, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { ErrorBoundary } from './src/components/ErrorBoundary';
import { AnthillScene, type SimStats, type ViewMode } from './src/components/AnthillScene';
import { World } from './src/simulation/world';

export default function App() {
  const worldRef = useRef<World | null>(null);
  if (!worldRef.current) {
    worldRef.current = new World();
  }

  const [viewMode, setViewMode] = useState<ViewMode>('surface');
  const [stats, setStats] = useState<SimStats>({
    tick: 0,
    foodDelivered: 0,
    antsForaging: 0,
    looseGrains: 0,
  });

  const onStats = useCallback((s: SimStats) => {
    setStats(s);
  }, []);

  const toggleView = useCallback(() => {
    setViewMode((v) => (v === 'surface' ? 'underground' : 'surface'));
  }, []);

  return (
    <ErrorBoundary>
      <View style={styles.root}>
        <StatusBar style="light" />
        <View style={styles.hud}>
          <Text style={styles.title}>Anthill</Text>
          <Text style={styles.line}>Ticks: {stats.tick}</Text>
          <Text style={styles.line}>Food delivered to nest: {stats.foodDelivered}</Text>
          <Text style={styles.line}>Foragers (active): {stats.antsForaging}</Text>
          <Text style={styles.line}>Loose sand grains (excavated): {stats.looseGrains}</Text>
        <Text style={styles.hint}>
          Tan discs: food patches. Center mound: nest. Ants use a correlated random walk; carriers get a weak
          scent bias toward the nest. Digging carves the sand heightfield and drops loose grains.
        </Text>
          <Pressable style={styles.btn} onPress={toggleView}>
            <Text style={styles.btnText}>
              {viewMode === 'surface' ? 'Show underground (X-ray)' : 'Show surface'}
            </Text>
          </Pressable>
        </View>
        <View style={styles.canvas}>
          <AnthillScene world={worldRef.current!} viewMode={viewMode} onStats={onStats} />
        </View>
      </View>
    </ErrorBoundary>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    width: '100%',
    backgroundColor: '#0f1419',
  },
  hud: {
    paddingTop: 14,
    paddingHorizontal: 14,
    paddingBottom: 8,
    backgroundColor: '#151c24ee',
    gap: 4,
    zIndex: 2,
  },
  title: {
    color: '#e8f0e6',
    fontSize: 20,
    fontWeight: '700',
    marginBottom: 4,
  },
  line: {
    color: '#c5d4c8',
    fontSize: 13,
  },
  hint: {
    color: '#8fa396',
    fontSize: 11,
    marginTop: 6,
    lineHeight: 15,
  },
  btn: {
    alignSelf: 'flex-start',
    marginTop: 10,
    backgroundColor: '#2d4a32',
    paddingVertical: 10,
    paddingHorizontal: 14,
    borderRadius: 8,
  },
  btnText: {
    color: '#eef5ef',
    fontSize: 14,
    fontWeight: '600',
  },
  canvas: {
    flex: 1,
    minHeight: 0,
    width: '100%',
    alignSelf: 'stretch',
  },
});
