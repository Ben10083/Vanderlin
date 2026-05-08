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
  const { outlaws } = data;
  // use modulo (%) to later have it so for every 3, we add a new row.
  return(
    <Table>
      <Table.Row>
        for (const outlaw of outlaws) {
          <Table.Cell>
            <Table.Row>
              (outlaw.name)
            </Table.Row>
            <Table.Row>
              (outlaw.reason)
            </Table.Row>
          </Table.Cell>
        }
      </Table.Row>
    </Table>
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
          {DisplayOutlaws(props)}
        </Section>
      </Window.Content>
    </Window>
  );
};
