import { render } from '@testing-library/react';
import App from './src/App';
import { describe, it, expect } from 'vitest';

describe('App component', () => {
  it('renders without crashing', () => {
    render(<App />);
    expect(true).toBe(true);
  });
});
