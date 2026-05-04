import { useBackend } from '../backend';
import { useLocalState } from '../backend';
import { Box, Button, DmIcon, Icon, Input, Section, Stack, Tooltip } from 'tgui-core/components';
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

const DisplayOutlaws = (props) => {
  const { act, data } = useBackend<Data>();
  const { outlaws } = data;

  return(
    <Table>

    </Table>
  );
};

const OutlawPoster = (props: WantedPosterProps) =>{
  const { outlaw } = props;

};

export const WantedPoster = (props) => {
  const { data } = useBackend<Data>();
  const { outlaw_power, outlaws, requested_outlaws } = data;

  return (
    <Window
      title="Language Menu"
      width={600}
      height={600}
    >
      <Window.Content>
        <Section
          scrollable
          fill
        >
          DisplayOutlaws
        </Section>
      </Window.Content>
    </Window>
  );
};
