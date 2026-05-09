import { useBackend } from '../backend';
import { useLocalState } from '../backend';
import { Box, Button, DmIcon, Icon, Input, Section, Table, Stack, Tooltip } from 'tgui-core/components';
import { Window } from '../layouts';

type Outlaw = {
  name: string;
  icon: string;
  reason: string;
}

type RequestOutlaw = {
  name: string;
  icon: string;
  reason: string;
  requestee: string;
}

type Data = {
  outlaw_power: number;
  outlaws: Outlaw[];
  requested_outlaws: RequestOutlaw[];
};

type WantedPosterProps = {
  outlaw: Outlaw;
};

type RequestPosterProps = {
  request: RequestOutlaw;
}

const DisplayOutlaws = (props) => {
  const { act, data } = useBackend<Data>();
  const { outlaws = [] } = data;
  // use modulo (%) to later have it so for every 3, we add a new row.
  return(
    <Box style={{ flex: 1, height: '100%', overflow: 'visible', display: 'flex', flexDirection: 'column'}}>
      {outlaws.map((outlaw, outlawIdx) => (
        <div style={{text-align: 'center', background: 'orange'}}>
          (outlaw.name)
          DEAD OR ALIVE
        </div>
    ))}
    </Box>
  );
};

const OutlawPoster = (props: WantedPosterProps) =>{
  const { outlaw } = props;

};

export const WantedPoster = (props) => {
  const { data } = useBackend<Data>();
  const { outlaw_power, outlaws = [], requested_outlaws = []} = data;

  return (
    <Window
      title="Wanted Poster"
      width={600}
      height={600}
    >
      <Window.Content>
        <Section
          scrollable
          fill
        >
          {DisplayOutlaws(prop = outlaws)}
        </Section>
      </Window.Content>
    </Window>
  );
};
