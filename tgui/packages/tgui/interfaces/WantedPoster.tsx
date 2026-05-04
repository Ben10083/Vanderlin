import { useBackend } from '../backend';
import { useLocalState } from '../backend';
import { Box, Button, DmIcon, Icon, Input, Stack, Tooltip } from 'tgui-core/components';
import { Window } from '../layouts';

type WantedPosterOutlaw = {
  name: string;
  icon: string;
  reason: string;
}

type WantedPosterRequestOutlaw = {
  name: string;
  icon: string;
  reason: string;
  requestee: string;
}

type Data = {
  outlaw_power: number;
};


